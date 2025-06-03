RSpec.describe "Ethiopia lookup in monthly System" do
  let(:period) { "2016NovQ1" }

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
        path:          "4/3/1",
        name:          "ABCD",
        group_ext_ids: %w[primary cs contracgroup1]
      ),
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "2",
        path:          "4/3/2",
        name:          "EFGH",
        group_ext_ids: %w[cs contracgroup1]
      )
    ]
  end

  let(:states) { %i[declared verified price] }

  let(:activities) do
    (1..2).map do |activity_index|
      activity_code = "act#{activity_index}"
      activity_states = states.map do |state|
        Orbf::RulesEngine::ActivityState.new_data_element(
          state:  state,
          ext_id: "dhis2_#{activity_code}_#{state}",
          name:   "#{activity_code}_#{state}",
          origin: "dataValueSets"
        )
      end
      Orbf::RulesEngine::Activity.with(
        name:            activity_code,
        activity_code:   activity_code,
        activity_states: activity_states
      )
    end
  end

  let(:single_package) do
    Orbf::RulesEngine::Package.new(
      code:                        :quantity,
      kind:                        :single,
      frequency:                   :monthly,
      main_org_unit_group_ext_ids: %w[cs],
      groupset_ext_id:             nil,
      activities:                  activities,
      rules:                       [
        Orbf::RulesEngine::Rule.new(
          kind:     :activity,
          formulas: [
            build_activity_formula(
              "verified_price", "(verified_quarterly - declared) * price_level_2_quarterly_nov",
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
    )
  end

  let(:single_payment_rule) do
    Orbf::RulesEngine::PaymentRule.new(
      code:      "pbf_payment",
      frequency: :quarterly_nov,
      packages:  [
        single_package
      ],
      rule:      Orbf::RulesEngine::Rule.new(
        kind:     "payment",
        formulas: [
          Orbf::RulesEngine::Formula.new(
            "monthly_quantity_production",
            "fosa_package_total + fosa_package_total "
          )
        ]
      )
    )
  end

  let(:project) do
    Orbf::RulesEngine::Project.new(
      calendar:      ::Orbf::RulesEngine::EthiopianV2Calendar.new(),
      packages:      [
        single_package
      ],
      payment_rules: [
        single_payment_rule
      ]
    )
  end

  let(:dhis2_values) do
    [
     
    { "dataElement" => "dhis2_act1_verified", "categoryOptionCombo" => "default", "value" => "18", "period" => "2016NovQ1", "orgUnit" => "1" },
    
    { "dataElement" => "dhis2_act1_price", "categoryOptionCombo" => "default", "value" => "99", "period" => "2016NovQ1", "orgUnit" => "3" },      
    { "dataElement" => "dhis2_act2_price", "categoryOptionCombo" => "default", "value" => "199", "period" => "2016NovQ1", "orgUnit" => "3" },      

      { "dataElement" => "dhis2_act1_declared", "categoryOptionCombo" => "default", "value" => "1", "period" => "201511", "orgUnit" => "1" },
      { "dataElement" => "dhis2_act1_declared", "categoryOptionCombo" => "default", "value" => "2", "period" => "201512", "orgUnit" => "1" },
      { "dataElement" => "dhis2_act1_declared", "categoryOptionCombo" => "default", "value" => "3", "period" => "201601", "orgUnit" => "1" }
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
    expect(problem["quantity_act1_verified_price_for_1_and_201511"]).to eq("(quantity_act1_verified_for_1_and_201511 - quantity_act1_declared_for_1_and_201511) * quantity_act1_price_level_2_quarterly_nov_for_3_and_201511")
  end

  let(:expected_problem) { JSON.parse(fixture_content(:rules_engine, "ethiopia_v2_problem.json")) }
  it "should build problem based on variables" do
    solver = build_solver(orgunits, dhis2_values)
    problem = solver.build_problem
    puts JSON.pretty_generate(problem) if problem != expected_problem
    expect(problem).to eq(expected_problem)
  end


  let(:expected_solution) { JSON.parse(fixture_content(:rules_engine, "ethiopia_v2_solution.json")) }

  it "should solve equations" do
    solution = solver.solve!
    #puts JSON.pretty_generate(solution)

    # expect(solution["quantity_fosa_package_total_for_2_and_2016q1"]).to eq(180.0)
    # expect(solution["quantity_fosa_package_total_for_1_and_2016q1"]).to eq(121_235.0)

    Orbf::RulesEngine::InvoiceCliPrinter.new(solver.variables, solver.solution).print
    if (solver.solution != expected_solution) 
      puts(JSON.pretty_generate(solver.solution))
    end
    expect(solver.solution).to eq(expected_solution)
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
      invoicing_period: period
    ).call

    package_vars = Orbf::RulesEngine::ActivityVariablesBuilder.to_variables(package_arguments, dhis2_values)

    Orbf::RulesEngine::SolverFactory.new(
      project,
      package_arguments,
      package_vars,
      period
    ).new_solver
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
end
