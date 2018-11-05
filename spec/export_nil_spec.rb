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

  let(:activity) do
    Orbf::RulesEngine::Activity.with(
      name:            "act1",
      activity_code:   "act1",
      activity_states: [
        Orbf::RulesEngine::ActivityState.new_data_element(
          state:  :achieved,
          ext_id: "dhis2_act1_achieved",
          name:   "act1_achieved"
        )
      ]
    )
  end

  let(:package) do
    Orbf::RulesEngine::Package.new(
      code:                   :quantity,
      kind:                   :single,
      frequency:              :quarterly,
      activities:             [activity],
      main_org_unit_group_ext_ids: ["contracgroup1"],
      rules:                  [
        Orbf::RulesEngine::Rule.new(
          kind:     :activity,
          formulas: [
            Orbf::RulesEngine::Formula.new(
              "score", "safe_div(achieved, 10)", "",
              activity_mappings:       {
                "act1" => "de_act1_achieved"
              },
              exportable_formula_code: "score_exportable"
            ),
            Orbf::RulesEngine::Formula.new(
              "score_exportable", "if((achieved_is_null  == 0 ), 1, 0)", ""
            )
          ]
        ),
        Orbf::RulesEngine::Rule.new(
          kind:     :package,
          formulas: [
            Orbf::RulesEngine::Formula.new(
              "package_score", "sum(%{score_values})", "",
              single_mapping:          "de_package_score",
              exportable_formula_code: "package_score_exportable"
            ),
            Orbf::RulesEngine::Formula.new(
              "package_score_exportable", "sum(%{score_exportable_values})", ""
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
      packages:  [package],
      rule:      Orbf::RulesEngine::Rule.new(
        kind:     "payment",
        formulas: [
          Orbf::RulesEngine::Formula.new(
            "rbf_amount",
            "package_score * 100",
            "",
            single_mapping:          "payment_de",
            exportable_formula_code: "rbf_exportable"
          ),
          Orbf::RulesEngine::Formula.new(
            "rbf_exportable",
            "package_score_exportable", ""
          )
        ]
      )
    )
  end

  let(:project) do
    Orbf::RulesEngine::Project.new(
      packages:      [
        package
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

  describe "when no data" do
    let(:fetch_and_solve) do
      Orbf::RulesEngine::FetchAndSolve.new(
        project,
        "1",
        "2018Q1",
        pyramid:     pyramid,
        mock_values: []
      )
    end

    it "exports nil values to dhis2 when no dhis2 values" do
      fetch_and_solve.call

      invoices = Orbf::RulesEngine::InvoicePrinter.new(
        fetch_and_solve.solver.variables,
        fetch_and_solve.solver.solution
      ).print

      invoice = invoices.first
      expect(invoice.activity_items.last.not_exported?("score")).to eq(true)
      expect(invoice.total_items.first.not_exported?).to eq(true)
      expect(invoice.total_items.first.explanations.map(&:strip)).to eq(
        [
          "sum(%{score_values})",
          "sum(0)",
          "sum(quantity_act1_score_for_1_and_2018q1)",
          "export ? package_score_exportable = sum(%{score_exportable_values})",
          "export ? package_score_exportable = sum(quantity_act1_score_exportable_for_1_and_2018q1)",
          "export ? package_score_exportable = sum(0)",
          "export ? package_score_exportable = 0"
        ]
      )

      expect(fetch_and_solve.exported_values).to eq(
        [
          { dataElement: "de_act1_achieved",
            orgUnit:     "1",
            period:      "2018Q1",
            value:       nil,
            comment:     "quantity_act1_score_for_1_and_2018q1" },
          { dataElement: "de_package_score",
            orgUnit:     "1",
            period:      "2018Q1",
            value:       nil,
            comment:     "quantity_package_score_for_1_and_2018q1" },
          { dataElement: "payment_de",
            orgUnit:     "1",
            period:      "2018Q1",
            value:       nil,
            comment:     "pbf_payment_rbf_amount_for_1_and_2018q1" }
        ]
      )
    end
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
            "orgUnit"     => "1",
            "period"      => "2018Q1",
            "dataElement" => "dhis2_act1_achieved",
            "value"       => "9"
          }
        ]
      )
    end

    it "exports non nil values to dhis2" do
      fetch_and_solve.call

      invoices = Orbf::RulesEngine::InvoicePrinter.new(
        fetch_and_solve.solver.variables,
        fetch_and_solve.solver.solution
      ).print

      invoice = invoices.first
      expect(invoice.activity_items.last.not_exported?("score")).to eq(false)
      expect(invoice.total_items.first.not_exported?).to eq(false)

      expect(fetch_and_solve.exported_values).to eq(
        [
          { dataElement: "de_act1_achieved",
            orgUnit:     "1",
            period:      "2018Q1",
            value:       0.9,
            comment:     "quantity_act1_score_for_1_and_2018q1" },
          { dataElement: "de_package_score",
            orgUnit:     "1",
            period:      "2018Q1",
            value:       0.9,
            comment:     "quantity_package_score_for_1_and_2018q1" },
          { dataElement: "payment_de",
            orgUnit:     "1",
            period:      "2018Q1",
            value:       90,
            comment:     "pbf_payment_rbf_amount_for_1_and_2018q1" }
        ]
      )
    end
  end
end
