
RSpec.describe "Cameroon System" do
  let(:period) { "2016Q1" }

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

  let(:orgunits) do
    [
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "1",
        path:          "country_id/county_id/1",
        name:          "ABCD",
        group_ext_ids: %w[primary cs contracgroup1]
      ),
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "2",
        path:          "country_id/county_id/2",
        name:          "EFGH",
        group_ext_ids: %w[cs contracgroup1]
      )
    ]
  end

  let(:states) { %i[verified] }

  let(:activities) do
    (1..2).map do |activity_index|
      activity_code = "act#{activity_index}"
      activity_states = states.map do |state|
        Orbf::RulesEngine::ActivityState.new_data_element(
          state:  state,
          ext_id: "dhis2_#{activity_code}_#{state}",
          name:   "#{activity_code}_#{state}"
        )
      end
      activity_states.push(
        Orbf::RulesEngine::ActivityState.new_constant(
          state:   "price",
          name:    "#{activity_code}_price",
          formula: (10 * activity_index).to_s
        )
      )
      Orbf::RulesEngine::Activity.with(
        activity_code:   activity_code,
        activity_states: activity_states
      )
    end
  end

  let(:project) do
    Orbf::RulesEngine::Project.new(
      packages: [
        Orbf::RulesEngine::Package.new(
          code:                   :quantity,
          kind:                   :single,
          frequency:              :quarterly,
          org_unit_group_ext_ids: %w[cs],
          groupset_ext_id:        nil,
          activities:             activities,
          rules:                  [
            Orbf::RulesEngine::Rule.new(
              kind:     :activity,
              formulas: [
                build_activity_formula(
                  "verified_price", "verified * price",
                  "Activity amount"
                )
              ]
            ),
            Orbf::RulesEngine::Rule.new(
              kind:     :package,
              formulas: [
                build_formula(
                  "fosa_package_total", "SUM(%{verified_price_values})"
                )
              ]
            )
          ]
        ),
        Orbf::RulesEngine::Package.new(
          code:                   :quantity_subcontract,
          kind:                   :subcontract,
          frequency:              :quarterly,
          org_unit_group_ext_ids: ["primary"],
          groupset_ext_id:        "contracts_groupset_ext_id",
          activities:             activities,
          rules:                  [
            Orbf::RulesEngine::Rule.new(
              kind:     :activity,
              formulas: [
                build_activity_formula(
                  "verified_price", "verified * price",
                  "Activity amount"
                ),
                build_activity_formula(
                  "average_amount", "(verified * price) / org_units_count",
                  "average amount"
                )
              ]
            ),
            Orbf::RulesEngine::Rule.new(
              kind:     :package,
              formulas: [
                build_formula(
                  "fosa_package_total", "SUM(%{verified_price_values})"
                )
              ]
            )
          ]
        )
      ]
    )
  end

  let(:dhis2_values) do
    [
      { "dataElement" => "dhis2_act1_verified", "categoryOptionCombo" => "default", "value" => "33", "period" => "2016Q1", "orgUnit" => "1" },
      { "dataElement" => "dhis2_act2_verified", "categoryOptionCombo" => "default", "value" => "80", "period" => "2016Q1", "orgUnit" => "1" },

      { "dataElement" => "dhis2_act1_verified", "categoryOptionCombo" => "default", "value" => "12", "period" => "2016Q1", "orgUnit" => "2" },
      { "dataElement" => "dhis2_act2_verified", "categoryOptionCombo" => "default", "value" => "92", "period" => "2016Q1", "orgUnit" => "2" },
    ]
  end

  def build_formula(code, expression, comment = nil)
    Orbf::RulesEngine::Formula.new(code, expression, comment, single_mapping: "dhis2_dataelement_id_#{code}")
  end

  def build_activity_formula(code, expression, comment = nil)
    Orbf::RulesEngine::Formula.new(code, expression, comment, activity_mappings: build_activity_mappings(code))
  end

  def build_activity_mappings(formula_code)
    activities.each_with_object({}) do |activity, mappings|
      mappings[activity.activity_code] = "dhis2_dataelement_id_#{formula_code} #{activity.activity_code}"
    end
  end

  let(:solver) do
    build_solver(orgunits, dhis2_values)
  end

  it "should register activity_variables" do
    problem = build_solver(orgunits, dhis2_values).build_problem
    expect(problem["quantity_act1_verified_for_1_and_2016q1"]).to eq("33")
  end

  let(:expected_problem) { JSON.parse(fixture_content(:rules_engine, "cameroon_problem.json")) }
  it "should build problem based on variables" do
    solver = build_solver(orgunits, dhis2_values)
    problem = solver.build_problem
    puts JSON.pretty_generate(problem) if problem != expected_problem
    expect(problem).to eq(expected_problem)
  end

  it "should solve equations" do
    solution = solver.solve!

    # expect(solution["quantity_fosa_package_total_for_2_and_2016q1"]).to eq(180.0)
    # expect(solution["quantity_fosa_package_total_for_1_and_2016q1"]).to eq(121_235.0)

    Orbf::RulesEngine::InvoicePrinter.new(solver.variables, solver.solution).print
    # exported_values = Orbf::RulesEngine::Dhis2ValuesPrinter.new(solver.variables, solver.solution).print
    # expect(exported_values).to include(
    #   data_element: "dhis2_dataelement_id_fosa_indicators_reported_weighted",
    #   org_unit:     "14",
    #   period:       "2016Q1",
    #   value:        9,
    #   comment:      "quantity_fosa_package_total_for_2_and_2016q1"
    # )
  end

  def build_solver(orgunits, dhis2_values)
    pyramid = Orbf::RulesEngine::Pyramid.new(
      org_units:          orgunits,
      org_unit_groups:    orgunit_groups,
      org_unit_groupsets: [groupset]
    )


    package_arguments = Orbf::RulesEngine::ResolveArguments.new(
      project:          project,
      pyramid:          pyramid,
      orgunit_ext_id:   orgunits[0].ext_id,
      invoicing_period: "2016Q1"
    ).call

    package_vars = Orbf::RulesEngine::ActivityVariablesBuilder.to_variables(package_arguments, dhis2_values)


    Orbf::RulesEngine::SolverFactory.new(
      project,
      package_arguments,
      package_vars,
      period
    ).new_solver
  end
end
