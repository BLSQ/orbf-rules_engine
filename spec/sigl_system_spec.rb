
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

def fetch_and_solve(project, pyramid, mock_values)
  Orbf::RulesEngine::FetchAndSolve.new(
    project,
    "state_id",
    "2016Q1",
    pyramid:     pyramid,
    mock_values: mock_values
  )
end

RSpec.describe "SIGL System" do
  let(:orgunits) do
    [
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "state_id",
        path:          "country_id/state_id",
        name:          "State 1",
        group_ext_ids: %w[states_group_id]
      ),
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "1",
        path:          "country_id/state_id/1",
        name:          "PMA 1",
        group_ext_ids: %w[pbf-pma]
      ),
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "2",
        path:          "country_id/state_id/2",
        name:          "PMA 2",
        group_ext_ids: %w[pbf-pma]
      )
    ]
  end

  let(:orgunit_groups) do
    [
      Orbf::RulesEngine::OrgUnitGroup.with(
        ext_id: "states_group_id",
        code:   "States 1",
        name:   "States 1"
      ),
      Orbf::RulesEngine::OrgUnitGroup.with(
        ext_id: "pbf-pma",
        code:   "PBF-PMA",
        name:   "PBF-PMA"
      )
    ]
  end

  let(:pyramid) do
    Orbf::RulesEngine::Pyramid.new(
      org_units:          orgunits,
      org_unit_groups:    orgunit_groups,
      org_unit_groupsets: []
    )
  end

  let(:project) do
    Orbf::RulesEngine::Project.new(
      packages:      [
        zone_package
      ],
      payment_rules: [],
      dhis2_params: {
        url:      "https://admin:district@play.dhis2.org/2.28",
        user:     "admin",
        password: "district"
      }
    )
  end

  let(:de_states) do
    %w[stock_start stock_end]
  end

  let(:activities) do
    (1..2).map do |activity_index|
      activity_code = "act#{activity_index}"
      activity_states = de_states.map do |state|
        Orbf::RulesEngine::ActivityState.new_data_element(
          state:  state,
          ext_id: "dhis2_#{activity_code}_#{state}",
          name:   "#{activity_code}_#{state}"
        )
      end
      Orbf::RulesEngine::Activity.with(
        name:            activity_code,
        activity_code:   activity_code,
        activity_states: activity_states
      )
    end
  end

  let(:zone_package) do
    org_units_count = Orbf::RulesEngine::ContractVariablesBuilder::ORG_UNITS_COUNT
      Orbf::RulesEngine::Package.new(
        code:                   :sigl_zone,
        kind:                   :zone,
        frequency:              :quarterly,
        main_org_unit_group_ext_ids: %w[states_group_id],
        target_org_unit_group_ext_ids: %w[pbf-pma],
        groupset_ext_id:        nil,
        activities:             activities,
        rules:                  [
          Orbf::RulesEngine::Rule.new(
            kind:     :activity,
            formulas: [
              build_activity_formula(
                "balance", "stock_start - stock_end"
              )
            ]
          ),
          Orbf::RulesEngine::Rule.new(
            kind:     :zone_activity,
            formulas: [
              build_formula(
                "total_balance_by_activity", "SUM(%{balance_values})"
              ),
              # Replace with actual count
              build_formula(
                "balance_divided_by_org_units_count", "SAFE_DIV(total_balance_by_activity,#{org_units_count})"
              )
            ]
          )
        ]
      )
  end

  let(:mock_values) do
    [
      { "dataElement" => "dhis2_act1_stock_start", "categoryOptionCombo" => "default", "value" => "10", "period" => "2016Q1", "orgUnit" => "1" },
      { "dataElement" => "dhis2_act1_stock_start", "categoryOptionCombo" => "default", "value" => "20", "period" => "2016Q1", "orgUnit" => "2" },
      { "dataElement" => "dhis2_act2_stock_start", "categoryOptionCombo" => "default", "value" => "100", "period" => "2016Q1", "orgUnit" => "1" },
      { "dataElement" => "dhis2_act2_stock_start", "categoryOptionCombo" => "default", "value" => "200", "period" => "2016Q1", "orgUnit" => "2" },
      { "dataElement" => "dhis2_act2_stock_start", "categoryOptionCombo" => "default", "value" => "200", "period" => "2016Q1", "orgUnit" => "3" }
    ]
  end

  it 'loads pyramid' do
    expect(pyramid).to_not be_nil
  end

  it 'load project' do
    expect(project).to_not be_nil
  end

  it "should build problem based on variables" do
    mock_values = []
    thing = fetch_and_solve(project, pyramid, mock_values)
    thing.call
    problem = thing.solver.build_problem
    expect(problem["sigl_zone_act1_total_balance_by_activity_for_state_id_and_2016q1"]).to eq("SUM(sigl_zone_act1_balance_for_1_and_2016q1, sigl_zone_act1_balance_for_2_and_2016q1)")
    expect(problem["sigl_zone_act2_total_balance_by_activity_for_state_id_and_2016q1"]).to eq("SUM(sigl_zone_act2_balance_for_1_and_2016q1, sigl_zone_act2_balance_for_2_and_2016q1)")
    expect(problem["sigl_zone_act1_balance_divided_by_org_units_count_for_state_id_and_2016q1"]).to eq("SAFE_DIV(sigl_zone_act1_total_balance_by_activity_for_state_id_and_2016q1,2)")
    expect(problem["sigl_zone_act2_balance_divided_by_org_units_count_for_state_id_and_2016q1"]).to eq("SAFE_DIV(sigl_zone_act2_total_balance_by_activity_for_state_id_and_2016q1,2)")
  end

  it "has a solution" do
    thing = fetch_and_solve(project, pyramid, mock_values)
    thing.call
    problem = thing.solver.build_problem
    solution = thing.solver.solution
    expect(solution["sigl_zone_act1_balance_divided_by_org_units_count_for_state_id_and_2016q1"]).to eq((10+20)/2.0)
    expect(solution["sigl_zone_act2_balance_divided_by_org_units_count_for_state_id_and_2016q1"]).to eq((100+200)/2.0)

    expect(solution["sigl_zone_act1_total_balance_by_activity_for_state_id_and_2016q1"]).to eq(10+20)
    expect(solution["sigl_zone_act2_total_balance_by_activity_for_state_id_and_2016q1"]).to eq(100+200)
  end

  it 'has expected solution' do
    thing = fetch_and_solve(project, pyramid, mock_values)
    thing.call
    problem = thing.solver.build_problem
    expected = JSON.parse(fixture_content(:rules_engine, "sigl_solution.json"))
    expect(thing.solver.solution).to eq(expected)
  end

  it 'has expected problem' do
    thing = fetch_and_solve(project, pyramid, mock_values)
    thing.call
    problem = thing.solver.build_problem
    expected = JSON.parse(fixture_content(:rules_engine, "sigl_problem.json"))
    expect(thing.solver.build_problem).to eq(expected)
  end

  it "uses zone activity variable" do
    thing = fetch_and_solve(project, pyramid, mock_values)
    thing.call
    solver = thing.solver
    key = "sigl_zone_act1_total_balance_by_activity_for_state_id_and_2016q1"
    variable = solver.variables.detect { |variable| variable.key == key }
    expected_variable = Orbf::RulesEngine::Variable.new_zone_activity_rule(
      period:         "2016Q1",
      key:            key,
      expression:     "SUM(sigl_zone_act1_balance_for_1_and_2016q1, sigl_zone_act1_balance_for_2_and_2016q1)",
      state:          "total_balance_by_activity",
      activity_code:  "act1",
      orgunit_ext_id: "state_id",
      formula:        project.packages.first.zone_activity_rules.first.formulas.first,
      package:        project.packages.first,
      payment_rule:   nil
    )
    expect(Array(variable)).to eq_vars(Array(expected_variable))
  end

end
