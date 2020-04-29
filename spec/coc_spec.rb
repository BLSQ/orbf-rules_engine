RSpec.describe "allow to export nil" do
  let(:orgunit) do
    Orbf::RulesEngine::OrgUnit.with(
      ext_id:        "1",
      path:          "country_id/county_id/1",
      name:          "African Foundation Baptist",
      group_ext_ids: ["contracgroup1"]
    )
  end

  let(:groupset) do
    Orbf::RulesEngine::OrgUnitGroupset.with(
      name:          "contracts",
      ext_id:        "contracts_groupset_ext_id",
      group_ext_ids: ["contracgroup1"],
      code:          "contracts"
    )
  end

  let(:orgunit_groups) do
    [
      Orbf::RulesEngine::OrgUnitGroup.with(
        ext_id: "contracgroup1",
        code:   "contract group 1",
        name:   "contract group 1"
      ),
      Orbf::RulesEngine::OrgUnitGroup.with(
        ext_id: "primary",
        code:   "primary",
        name:   "Primary"
      ),
      Orbf::RulesEngine::OrgUnitGroup.with(
        ext_id: "cs",
        code:   "cs",
        name:   "cs"
      )
    ]
  end

  let(:pyramid) do
    Orbf::RulesEngine::Pyramid.new(
      org_units:          [orgunit],
      org_unit_groups:    orgunit_groups,
      org_unit_groupsets: [groupset]
    )
  end

  let(:activity_a) do
    Orbf::RulesEngine::Activity.with(
      name:            "acta",
      activity_code:   "acta",
      activity_states: [
        Orbf::RulesEngine::ActivityState.new_indicator(
          state:      :stock_start,
          ext_id:     "dhis2acta.stockstartco",
          name:       "inlined-dhis2acta.stockstartco",
          origin:     "dataValueSets",
          expression: '#{dhis2acta.stockstartcoc}'
        ),
        Orbf::RulesEngine::ActivityState.new_indicator(
          state:      :stock_end,
          ext_id:     "dhis2acta.stockendcoc",
          name:       "inlined-dhis2acta.stockendcoc",
          origin:     "dataValueSets",
          expression: '#{dhis2acta.stockendcoc}'
        )

      ]
    )
  end

  let(:package_a) do
    Orbf::RulesEngine::Package.new(
      code:                        :quantity_a,
      kind:                        :single,
      frequency:                   :quarterly,
      activities:                  [activity_a],
      main_org_unit_group_ext_ids: ["contracgroup1"],
      rules:                       [
        Orbf::RulesEngine::Rule.new(
          kind:     :activity,
          formulas: [
            Orbf::RulesEngine::Formula.new(
              "consumption", "stock_start - stock_end", "",
              activity_mappings: {
                "acta" => "dhis2acta.consumptioncoc"
              }
            )

          ]
        )
      ]
    )
  end

  let(:activity_b) do
    Orbf::RulesEngine::Activity.with(
      name:            "actb",
      activity_code:   "actb",
      activity_states: [
        Orbf::RulesEngine::ActivityState.new_indicator(
          state:      :consumption,
          ext_id:     "dhis2acta.consumptioncoc",
          name:       "inlined-dhis2acta.consumptioncoc",
          origin:     "dataValueSets",
          expression: '#{dhis2acta.consumptioncoc}'
        ),
        Orbf::RulesEngine::ActivityState.new_indicator(
          state:      :stock_end,
          ext_id:     "dhis2acta.stockendcoc",
          name:       "inlined-dhis2acta.stockendcoc",
          origin:     "dataValueSets",
          expression: '#{dhis2acta.stockendcoc}'
        )
      ]
    )
  end

  let(:package_b) do
    Orbf::RulesEngine::Package.new(
      code:                        :quantity_b,
      kind:                        :single,
      frequency:                   :quarterly,
      activities:                  [activity_b],
      main_org_unit_group_ext_ids: ["contracgroup1"],
      rules:                       [
        Orbf::RulesEngine::Rule.new(
          kind:     :activity,
          formulas: [
            Orbf::RulesEngine::Formula.new(
              "score", "round(safe_div(consumption, stock_end) * 100,2)", "",
              activity_mappings: {
                "actb" => "dhis2actb.scorecoc"
              }
            )

          ]
        )
      ]
    )
  end

  let(:payment_rule) do
    Orbf::RulesEngine::PaymentRule.new(
      code:      "pbf_payment",
      frequency: :quarterly,
      packages:  [package_a, package_b],
      rule:      Orbf::RulesEngine::Rule.new(
        kind:     "payment",
        formulas: [
          Orbf::RulesEngine::Formula.new(
            "nothing",
            "1",
            "",
            single_mapping: "payment_de"
          )
        ]
      )
    )
  end

  let(:project) do
    Orbf::RulesEngine::Project.new(
      packages:      [
        package_a,
        package_b

      ],
      payment_rules: [
        payment_rule
      ],
      dhis2_params:  {
        url:      "https://admin:district@play.dhis2.org/2.28",
        user:     "admin",
        password: "district"
      }
    )
  end

  describe "when data" do
    let(:fetch_and_solve) do
      Orbf::RulesEngine::FetchAndSolve.new(
        project,
        "1",
        "2018Q1",
        pyramid:     pyramid,
        mock_values: [
          {
            "orgUnit"             => "1",
            "period"              => "2018Q1",
            "dataElement"         => "dhis2acta",
            "categoryOptionCombo" => "stockstartcoc",
            "value"               => "8"
          },
          {
            "orgUnit"             => "1",
            "period"              => "2018Q1",
            "dataElement"         => "dhis2acta",
            "categoryOptionCombo" => "stockendcoc",
            "value"               => "6"
          }
        ]
      )
    end

    it "aliases package a formula output to package b activity state and export the correct value for both packages" do
      # Package A will read from `dhis2acta` got get the `stock_start`
      # (`stockstartcoc`) and `stock_end` (`stockendcoc`), it will then
      # output a `comsumption` to `"dhis2acta.consumptioncoc"`.
      #
      # Package B will read from `dhis2acta` to get the `stock_end`
      # (`stockendcoc`) and from the newly created
      # `dhis2acta.consumptioncoc`
      #
      # So putting this all together, if `start_stock` is 8 and `stock_end`
      # is 6, the `consumption` will be 2 and that will be stored in
      # `dhis2acta.consumptioncoc`

      fetch_and_solve.call

      invoices = Orbf::RulesEngine::InvoicePrinter.new(
        fetch_and_solve.solver.variables,
        fetch_and_solve.solver.solution
      ).print

      invoice = invoices.first

      expect(fetch_and_solve.exported_values).to eq(
        [
          { dataElement: "dhis2acta", orgUnit: "1", period: "2018Q1",
              value: (8.0 - 6.0), comment: "quantity_a_acta_consumption_for_1_and_2018q1",
               categoryOptionCombo: "consumptioncoc" },
          { dataElement: "dhis2actb", orgUnit: "1", period: "2018Q1",
              value: (2.0 / 6.0 * 100).round(2), comment: "quantity_b_actb_score_for_1_and_2018q1",
              categoryOptionCombo: "scorecoc" },
          { dataElement: "payment_de", orgUnit: "1", period: "2018Q1",
              value: 1, comment: "pbf_payment_nothing_for_1_and_2018q1" }
        ]
      )
    end
  end
end
