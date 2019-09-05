RSpec.describe "Payers" do
  let(:period) { "2016Q1" }

  let(:activities) do
    [
      Orbf::RulesEngine::Activity.with(
        name:            "spread",
        activity_code:   "spread_01",
        activity_states: [
          Orbf::RulesEngine::ActivityState.new_data_element(
            state:                 "percentage",
            ext_id:                "dhis2_spread_percentage",
            name:                  "spread_percentage",
            origin:                "dataValueSets",
            category_combo_ext_id: "dhis2_payers"
          ),
          Orbf::RulesEngine::ActivityState.new_data_element(
            state:  "to_pay",
            ext_id: "dhis2_to_pay",
            name:   "spread_to_pay",
            origin: "dataValueSets"
          )
        ]
      )
    ]
  end

  let(:project) do
    Orbf::RulesEngine::Project.new(
      packages: [
        Orbf::RulesEngine::Package.new(
          code:                        :facility,
          kind:                        :single,
          frequency:                   :quarterly,
          main_org_unit_group_ext_ids: ["G_ID_1"],
          activities:                  activities,
          loop_over_combo:             { # TODO: move to a value object ? Orbf::RulesEngine::CategoryCombo
            id:                     "dhis2_payers",
            category_option_combos: [ # TODO: move to a value object ? Orbf::RulesEngine::CategoryOptionCombo
              {
                id: "dhis2_payer_1"
              },
              {
                id: "dhis2_payer_2"
              },
              {
                id: "dhis2_payer_3"
              }

            ]
          },

          rules:                       [
            Orbf::RulesEngine::Rule.new(
              kind:     :activity,
              formulas: [
                build_activity_formula(
                  "exportable", "percentage_is_null == 0",
                  "should only export when percentage is filled"
                ),
                build_activity_formula(
                  "percentage_calculated", " (percentage/100) * 0.20",
                  "should only export when percentage is filled"
                ),
                build_activity_formula(
                  "payer_payment", "to_pay * percentage_calculated",
                  ""
                )
              ]
            )
          ]
        )
      ]
    )
  end

  let(:orgunit_id) do
    "orgunit_id"
  end

  let(:orgunits_full) do
    [
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        orgunit_id,
        path:          "path",
        name:          "name",
        group_ext_ids: ["G_ID_1"]
      )
    ]
  end

  let(:org_unit_groups) do
    [
      Orbf::RulesEngine::OrgUnitGroup.with(
        ext_id: "G_ID_1",
        name:   "group health center",
        code:   "health_center"
      )
    ]
  end

  let(:dhis2_values) do
    [
      {
        "dataElement"         => "dhis2_to_pay",
        "categoryOptionCombo" => "default",
        "value"               => 10_000,
        "period"              => period,
        "orgUnit"             => orgunit_id
      },
      {
        "dataElement"         => "dhis2_spread_percentage",
        "categoryOptionCombo" => "dhis2_payer_1",
        "value"               => 10,
        "period"              => period,
        "orgUnit"             => orgunit_id
      },
      {
        "dataElement"         => "dhis2_spread_percentage",
        "categoryOptionCombo" => "dhis2_payer_2",
        "value"               => 60,
        "period"              => period,
        "orgUnit"             => orgunit_id
      }, {
        "dataElement"         => "dhis2_spread_percentage",
        "categoryOptionCombo" => "dhis2_payer_3",
        "value"               => 30,
        "period"              => period,
        "orgUnit"             => orgunit_id
      }
    ]
  end

  it "builds problem per category option combo" do
    solved = build_and_solve(orgunits_full, dhis2_values)
    problem = solved.solver.build_problem

    %w[dhis2_payer_1 dhis2_payer_2 dhis2_payer_3].each do |coc|
      expect(problem["facility_spread_01_#{coc}_exportable_for_orgunit_id_and_2016q1"]).to eq(
        "facility_spread_01_#{coc}_percentage_is_null_for_orgunit_id_and_2016q1 == 0"
      )
      expect(problem["facility_spread_01_#{coc}_percentage_calculated_for_orgunit_id_and_2016q1"]).to eq(
        "(facility_spread_01_#{coc}_percentage_for_orgunit_id_and_2016q1/100) * 0.20"
      )
      expect(problem["facility_spread_01_#{coc}_payer_payment_for_orgunit_id_and_2016q1"]).to eq(
        "facility_spread_01_to_pay_for_orgunit_id_and_2016q1 * facility_spread_01_#{coc}_percentage_calculated_for_orgunit_id_and_2016q1"
      )
    end
  end

  it "should solve equations" do
    solved = build_and_solve(orgunits_full, dhis2_values)

    expect(solved.solver.solution["facility_spread_01_dhis2_payer_1_percentage_calculated_for_orgunit_id_and_2016q1"]).to be_within(0.001).of(0.020)

    expect(solved.exported_values).to include(
      categoryOptionCombo: "dhis2_payer_1",
      comment:             "facility_spread_01_dhis2_payer_1_payer_payment_for_orgunit_id_and_2016q1",
      dataElement:         "dhis2_dataelement_id_payer_payment spread_01",
      orgUnit:             "orgunit_id",
      period:              "2016Q1",
      value:               200.00000000000003
    )

    expect(solved.exported_values).to include(
      categoryOptionCombo: "dhis2_payer_2",
      comment:             "facility_spread_01_dhis2_payer_2_payer_payment_for_orgunit_id_and_2016q1",
      dataElement:         "dhis2_dataelement_id_payer_payment spread_01",
      orgUnit:             "orgunit_id",
      period:              "2016Q1",
      value:               1200
    )

    expect(solved.exported_values).to include(
      categoryOptionCombo: "dhis2_payer_3",
      comment:             "facility_spread_01_dhis2_payer_3_payer_payment_for_orgunit_id_and_2016q1",
      dataElement:         "dhis2_dataelement_id_payer_payment spread_01",
      orgUnit:             "orgunit_id",
      period:              "2016Q1",
      value:               600
    )

  end

  def build_activity_formula(code, expression, comment = nil)
    Orbf::RulesEngine::Formula.new(code, expression, comment, activity_mappings: build_activity_mappings(code))
  end

  def build_activity_mappings(formula_code)
    activities.each_with_object({}) do |activity, mappings|
      mappings[activity.activity_code] = "dhis2_dataelement_id_#{formula_code} #{activity.activity_code}"
    end
  end

  def build_and_solve(orgs, dhis2_values)
    pyramid = Orbf::RulesEngine::Pyramid.new(
      org_units:          orgs,
      org_unit_groups:    org_unit_groups,
      org_unit_groupsets: []
    )

    fetch_and_solve = Orbf::RulesEngine::FetchAndSolve.new(
      project, orgs[0].ext_id, period,
      pyramid:     pyramid,
      mock_values: dhis2_values
    )

    fetch_and_solve.call

    fetch_and_solve
  end
end
