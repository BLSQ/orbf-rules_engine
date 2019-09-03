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
          loop_over_combo:             { # TODO move to a value object ? Orbf::RulesEngine::CategoryCombo
            id:                     "dhis2_payers",
            category_option_combos: [ # TODO move to a value object ? Orbf::RulesEngine::CategoryOptionCombo
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
        "dataElement":         "dhis2_spread_percentage",
        "categoryOptionCombo": "dhis2_payer_1",
        "value":               10,
        "period":              period,
        "orgUnit":             orgunit_id
      },
      {
        "dataElement":         "dhis2_spread_percentage",
        "categoryOptionCombo": "dhis2_payer_2",
        "value":               60,
        "period":              period,
        "orgUnit":             orgunit_id
      }, {
        "dataElement":         "dhis2_spread_percentage",
        "categoryOptionCombo": "dhis2_payer_3",
        "value":               30,
        "period":              period,
        "orgUnit":             orgunit_id
      }
    ]
  end

  let(:solver) { build_solver(orgunits_full, dhis2_values) }

  it "builds problem per category option combo" do
    puts JSON.pretty_generate(solver.build_problem)
    problem = solver.build_problem

    expect(problem["facility_spread_01_dhis2_payer_1_exportable_for_orgunit_id_and_2016q1"]).to eq(
      "facility_spread_01_dhis2_payer_1_percentage_is_null_for_orgunit_id_and_2016q1 == 0"
    )
    expect(problem["facility_spread_01_dhis2_payer_1_percentage_calculated_for_orgunit_id_and_2016q1"]).to eq(
      "(facility_spread_01_dhis2_payer_1_percentage_for_orgunit_id_and_2016q1/100) * 0.20"
    )
    expect(problem["facility_spread_01_dhis2_payer_1_payer_payment_for_orgunit_id_and_2016q1"]).to eq(
      "facility_spread_01_to_pay_for_orgunit_id_and_2016q1 * facility_spread_01_dhis2_payer_1_percentage_calculated_for_orgunit_id_and_2016q1"
    )
  end

  it "should solve equations" do
    solver.solve!

    expect(solver.solution["facility_spread_01_dhis2_payer_1_percentage_calculated_for_orgunit_id_and_2016q1"]).to be_within(0.001).of(0.020)

    Orbf::RulesEngine::InvoiceCliPrinter.new(solver.variables, solver.solution).print
  end

  def build_activity_formula(code, expression, comment = nil)
    Orbf::RulesEngine::Formula.new(code, expression, comment, activity_mappings: build_activity_mappings(code))
  end

  def build_activity_mappings(formula_code)
    activities.each_with_object({}) do |activity, mappings|
      mappings[activity.activity_code] = "dhis2_dataelement_id_#{formula_code} #{activity.activity_code}"
    end
  end

  def build_solver(orgs, dhis2_values)
    pyramid = Orbf::RulesEngine::Pyramid.new(
      org_units:          orgs,
      org_unit_groups:    org_unit_groups,
      org_unit_groupsets: []
    )
    package_arguments = Orbf::RulesEngine::ResolveArguments.new(
      project:          project,
      pyramid:          pyramid,
      orgunit_ext_id:   orgs[0].ext_id,
      invoicing_period: "2016Q1"
    ).call

    package_vars = Orbf::RulesEngine::ActivityVariablesBuilder.to_variables(package_arguments, dhis2_values)
    package_vars.push(*Orbf::RulesEngine::ActivityComboVariablesBuilder.to_variables(package_arguments, dhis2_values))
    Orbf::RulesEngine::SolverFactory.new(
      project,
      package_arguments,
      package_vars,
      period
    ).new_solver
  end
end
