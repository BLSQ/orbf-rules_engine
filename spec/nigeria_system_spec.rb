require "ruby-prof"
require "allocation_stats"

RSpec.describe "Nigeria System" do
  let(:period) { "2016Q1" }

  let(:orgunit_groups) do
    [
      Orbf::RulesEngine::OrgUnitGroup.with(
        ext_id: "states_group_id",
        code:   "States 1",
        name:   "States 1"
      ),
      Orbf::RulesEngine::OrgUnitGroup.with(
        ext_id: "pbf-cpa",
        code:   "PBF-CPA",
        name:   "PBF-CPA"
      ),
      Orbf::RulesEngine::OrgUnitGroup.with(
        ext_id: "pbf-pma",
        code:   "PBF-PMA",
        name:   "PBF-PMA"
      ),
      Orbf::RulesEngine::OrgUnitGroup.with(
        ext_id: "dff-pma",
        code:   "DFF-PMA",
        name:   "DFF-PMA"
      ),
      Orbf::RulesEngine::OrgUnitGroup.with(
        ext_id: "dff-cpa",
        code:   "DFF-CPA",
        name:   "DFF-CPA"
      )
    ]
  end

  let(:orgunits) do
    [
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "state_id",
        path:          "country_id/state_id",
        name:          "State 1",
        group_ext_ids: %w[states_group_id]
      ),
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "5",
        path:          "country_id/state_id/5",
        name:          "PMA 3",
        group_ext_ids: %w[dff-pma states_group_id]
      ),
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "1",
        path:          "country_id/state_id/1",
        name:          "PMA 1",
        group_ext_ids: %w[dff-pma]
      ),
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "2",
        path:          "country_id/state_id/2",
        name:          "PMA 2",
        group_ext_ids: %w[dff-pma]
      ),
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "3",
        path:          "country_id/state_id/3",
        name:          "PCA 1",
        group_ext_ids: %w[dff-cpa]
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

  let(:de_states) do
    %w[population payment]
  end

  let(:activities) do
    (1..1).map do |activity_index|
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

      Orbf::RulesEngine::Package.new(
        code:                   :payment_for_dff,
        kind:                   :zone,
        frequency:              :quarterly,
        main_org_unit_group_ext_ids: %w[states_group_id],
        target_org_unit_group_ext_ids: %w[dff-pma],
        groupset_ext_id:        nil,
        activities:             activities,
        rules:                  [
          Orbf::RulesEngine::Rule.new(
            kind:     :activity,
            formulas: [
              build_activity_formula(
                "act_ou_population", "population",
                "population"
              ),
              build_activity_formula(
                "act_ou_payment_pbf", "payment_zone_main_orgunit",
                "payment"
              )
            ]
          ),
          Orbf::RulesEngine::Rule.new(
            kind:     :package,
            formulas: [
              build_formula(
                "ou_population", "MAX(%{act_ou_population_values})"
              ),
              build_formula(
                "ou_population_weight", "SAFE_DIV(ou_population,state_population)"
              ),
              build_formula(
                "ou_payment", "ou_population_weight * SAFE_DIV(MAX(%{act_ou_payment_pbf_values}),2)"
              ),
            ]
          ),
          Orbf::RulesEngine::Rule.new(
            kind:     :zone,
            formulas: [
              build_formula(
                "state_population", "SUM(%{ou_population_values})"
              ),
              build_formula(
                "state_total_payment", "SUM(%{ou_payment_values})"
              )
            ]
          )
        ]
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

  let(:pbf_total_payment) do
    32000
  end

  let (:mock_values) do
    [
      { "dataElement" => "dhis2_act1_population", "categoryOptionCombo" => "default", "value" => "33", "period" => "2016", "orgUnit" => "1" },
      { "dataElement" => "dhis2_act1_population", "categoryOptionCombo" => "default", "value" => "80", "period" => "2016", "orgUnit" => "2" },
      { "dataElement" => "dhis2_act1_population", "categoryOptionCombo" => "default", "value" => "41", "period" => "2016", "orgUnit" => "3" },
      { "dataElement" => "dhis2_act1_population", "categoryOptionCombo" => "default", "value" => "32", "period" => "2016", "orgUnit" => "5" },
      { "dataElement" => "dhis2_act1_payment", "categoryOptionCombo" => "default", "value" => "#{pbf_total_payment}", "period" => "2016Q1", "orgUnit" => "state_id" }
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



  let(:fetch_and_solve) do
    Orbf::RulesEngine::FetchAndSolve.new(
      project,
      "state_id",
      "2016Q1",
      pyramid:     pyramid,
      mock_values: mock_values
    )
  end

  let(:expected_problem) { JSON.parse(fixture_content(:rules_engine, "nigeria_problem.json")) }
  let(:expected_solution) { JSON.parse(fixture_content(:rules_engine, "nigeria_solution.json")) }
  it "should build problem based on variables" do
    fetch_and_solve.call
    problem = fetch_and_solve.solver.build_problem
    puts JSON.pretty_generate(problem) if problem != expected_problem
    expect(problem).to eq(expected_problem)
  end

  it "works" do
    # fetch_and_solve.call
    project
    pyramid

    RubyProf.start if ENV["PROF"]
    require "objspace"

    # stats = AllocationStats.trace do
    fetch_and_solve.call
    Orbf::RulesEngine::InvoicePrinter.new(fetch_and_solve.solver.variables, fetch_and_solve.solver.solution).print
    # end
    # puts stats.allocations(alias_paths: true).group_by(:sourcefile, :sourceline, :class).sort_by_count.to_text
    result = RubyProf.stop if ENV["PROF"]

    if ENV["PROF"]
      printer = RubyProf::GraphPrinter.new(result)
      printer.print(STDOUT, {})

      printer = RubyProf::FlatPrinter.new(result)
      printer.print(STDOUT, {})
    end
    solution =fetch_and_solve.solver.solution

    puts JSON.pretty_generate(solution) if solution != expected_solution
    expect(solution).to eq(expected_solution)

    expect(solution["state_total_payment_for_2016q1"]).to eq((pbf_total_payment/2))
  end
end
