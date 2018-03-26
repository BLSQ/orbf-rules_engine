require "stackprof"

RSpec.describe "System" do
  let(:period) { "2016Q1" }

  let(:regional_bonus) { 121_235 }

  let(:indicator_weights) { [6, 5, 5, 5, 5, 6, 10, 7, 5] }

  let(:indicator_caps) { [125, 125, 125, 125, 100, 125, 125, 100, 100] }
  let(:target_achieved_values) do
    {
      "African Foundation Baptist" => %w[33 33 80	79 3	3 37	0 30	33 35	23 80	65 1	1 0.78	0.90],
      "Bah-ta"                     => %w[66	73 9	9 3	3 111	20 61	66 71	73 90	65 0.08	1 0.7	1],
      "Botota"                     => %w[55	66 8	9 3	3 57	77 51	94 60	69 0 0	1	1 0 0],
      "CB-Dumbar"                  => %w[590	494 5	7 3	3 721	1026 545	457 638	321 0	0 1	1 0	0],
      "Deigei"                     => %w[38	41 4	7 3	3 38	0 35	44 41	41 0 0 1	1 0 0],
      "Fenutoli"                   => %w[71	95 8	6 3	3 157	149 66	77 77	96 0 0 1	1 0 0 0 0],
      "Gbalatuah"                  => %w[35	49 7	8 3	3 47 35 32 55 38 52 0 0 1	1 0 0],
      "Gbanla Community Clinic"    => %w[68	76 8	4 3	3 52 59 62 69 73 105 0	0 1	1 0	0],
      "Gbansuesuloma"              => %w[25	27 6	4 3	3 41	12 23	40 27	30 0 0 1	1 0 0],
      "Gbartala"                   => %w[167 172 7	6 3	3 177	76 154 179 181 327 0 0 1	1 0 0],
      "Gbecohn"                    => %w[72	79 5	9 3	3 41 17 67 87 78 81 0 0 1	1 0 0],
      "Handii"                     => %w[88	113 8	5 3	3 36	41 81	116 95	119 0 0 1	1 0 0 0 0],
      "Janyea"                     => %w[38	55 5	8 3	3 61	15 35	47 41	87 0	0 1	1 0	0],
      "Jorwah"                     => %w[20	39 7	4 3	3 163	109 18	36 21	44 0	0 1	1 0	0],
      "Naama Clinic"               => %w[68	84 6	9 3	3 73	84 63	77 74	126 0	0 1	1 0	0],
      "Phebe OPD"                  => %w[298	126 	0 0 3	3 328	213 275	339 322	253 0 0	 1	1 0 0	],
      "Samay"                      => %w[112	110 0	0 3	3 95	0 104	63 121	147 0	0 1	1 0	0],
      "Shankpalla"                 => %w[38	43 0	0 3	3 49	19 35	53 41	37 0	0 1	1 0	0],
      "Yolota"                     => %w[30	64 0 0	3	3 75	75 27	0 32	48 0 0	 1	1 0 0	],
      "Zeansue"                    => %w[102	102 0 0 3	3 124	50 94	140 110	117 0 0 1	1 0 0 0 0]
    }
  end

  let(:orgunits_full) do
    target_achieved_values.keys
                          .each_with_index
                          .map do |name, index|
      orgunit_id = (index + 1).to_s
      path = "country_id/county_id/#{orgunit_id}"
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        orgunit_id,
        path:          path,
        name:          name,
        group_ext_ids: ["G_ID_1"]
      )
    end
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

  let(:states) { %i[weight achieved target active cap health_clynic_type allowed regional_bonus] }

  let(:activities) do
    (1..9).map do |activity_index|
      activity_code = "act#{activity_index}"
      activity_states = states.map do |state|
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

  let(:dhis2_orgunit_values) do
    target_achieved_values.map { |k, v| [k, v] }
                          .each_with_index
                          .map do |kv, index|
      orgunit_name = kv.first
      values_as_strings = kv.last
      orgunit_id = (index + 1).to_s
      org_vals = values_as_strings.each_with_index.map do |value, activity_index|
        state = activity_index.even? ? "achieved" : "target"
        activity_code = "act#{(activity_index / 2).to_i + 1}"
        data_element_id = "dhis2_#{activity_code}_#{state}"
        {
          "dataElement":         data_element_id,
          "categoryOptionCombo": "default",
          "value":               value,
          "period":              period,
          "orgUnit":             orgunit_id,
          "comment":             "#{orgunit_name}-#{activity_index}"
        }
      end

      org_vals += values_as_strings.each_with_index.map do |_value, activity_index|
        state = "active"
        activity_code = "act#{(activity_index / 2).to_i + 1}"
        data_element_id = "dhis2_#{activity_code}_#{state}"
        {
          "dataElement":         data_element_id,
          "categoryOptionCombo": "default",
          "value":               "1",
          "period":              period,
          "orgUnit":             orgunit_id,
          "comment":             "#{orgunit_name}-#{activity_index}"
        }
      end

      org_vals.uniq
    end
  end

  let(:country_states) { %w[weight cap regional_bonus] }

  let(:dhis2_country_values) do
    value_registry = {
      "weight"         => indicator_weights,
      "cap"            => indicator_caps,
      "regional_bonus" => activities.map { |_v| regional_bonus }
    }

    activities.map do |activity|
      activity.activity_states.select { |as| country_states.include?(as.state) }
              .map do |activity_state|
        ids = activity_state.ext_id.split("_")
        activity_index = ids[1][3..-1].to_i - 1
        value = value_registry[activity_state.state][activity_index]

        {
          "dataElement":         activity_state.ext_id,
          "categoryOptionCombo": "default",
          "value":               value,
          "period":              period,
          "orgUnit":             "country_id",
          "comment":             "country-#{activity_state.ext_id}"
        }
      end
    end.flatten
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

  let(:project) do
    Orbf::RulesEngine::Project.new(
      packages: [
        Orbf::RulesEngine::Package.new(
          code:                   :facility,
          kind:                   :zone,
          frequency:              :quarterly,
          activities:             activities,
          groupset_ext_id:        "district_groupset_ext_id",
          rules:                  [
            Orbf::RulesEngine::Rule.new(
              kind:     :activity,
              formulas: [
                build_activity_formula(
                  "active_weight", "weight_level_1 * active",
                  "Column C Weight"
                ),
                build_activity_formula(
                  "actual_active", "active",
                  "new concept added to avoid handling nil vs 0"
                ),
                build_activity_formula(
                  "percent_weight", "safe_div(weight_level_1, fosa_total_actual_weight)"
                ),
                build_activity_formula(
                  "percent_achieved", "active * safe_div(achieved,target)",
                  "% of Target Achieved [B / C], B and C are from activity states"
                ),
                build_activity_formula(
                  "allowed_percent", "if (percent_achieved < 0.75, 0, min(percent_achieved, cap_level_1 / 100))",
                  "Allowed [E] : should achieve at least 75% and can not go further than the cap"
                ),
                build_activity_formula(
                  "overall", "allowed_percent * percent_weight",
                  "% Overall [A x E]"
                ),
                build_activity_formula(
                  "actual_health_clynic_type", "1", # TODO: health_clynic_type from decision table
                  "used for available bonus calculations see package and zone rules"
                ),
                build_activity_formula(
                  "actual_regional_bonus", "regional_bonus_level_1",
                  "used for available bonus calculations see package and zone rules"
                )
              ]
            ),
            Orbf::RulesEngine::Rule.new(
              kind:     :package,
              formulas: [
                build_formula(
                  "fosa_total_actual_weight", "SUM(%{active_weight_values})"
                ),
                build_formula(
                  "fosa_number_of_indicators_reported", "sum(%{actual_active_values})"
                ),
                build_formula(
                  "fosa_performance_score", "sum(%{overall_values})"
                ),
                build_formula(
                  "fosa_indicators_reported_weighted", "fosa_number_of_indicators_reported * Max(%{actual_health_clynic_type_values})"
                ),
                build_formula(
                  "fosa_indicators_reported_weighted_for_county", "safe_div(fosa_indicators_reported_weighted , county_total_indicators_reported_weighted)",
                  "reference a zone formula output for weighting on all fosa of the county"
                ),
                build_formula(
                  "fosa_available_budget", "fosa_indicators_reported_weighted_for_county * max(%{actual_regional_bonus_values})"
                )
              ]
            ),
            Orbf::RulesEngine::Rule.new(
              kind:     :zone,
              formulas: [
                Orbf::RulesEngine::Formula.new(
                  "county_total_indicators_reported_weighted", "SUM(%{fosa_indicators_reported_weighted_values})"
                ),
                Orbf::RulesEngine::Formula.new(
                  "county_total_available_budget_for_fosa", "SUM(%{fosa_available_budget_values})"
                )
              ]
            )
          ],
          org_unit_group_ext_ids: ["G_ID_1"]
        )
      ]
    )
  end

  let(:dhis2_values) do
    JSON.parse(JSON.generate((dhis2_orgunit_values + dhis2_country_values).flatten))
  end

  let(:solver) do
    build_solver(orgunits_full, dhis2_values)
  end

  let(:groupset) do
    Orbf::RulesEngine::OrgUnitGroupset.with(
      name:          "groupset",
      ext_id:        "district_groupset_ext_id",
      group_ext_ids: ["G_ID_1"],
      code:          "types"
    )
  end

  it "should register activity_variables" do
    solver = build_solver(orgunits_full, dhis2_values)
    expect(solver.build_problem["facility_act1_achieved_for_2_and_2016q1"]).to eq("66")
  end

  it "should be exportable to graphviz" do
    Orbf::RulesEngine::Log.call "------------------------- project"
    Orbf::RulesEngine::Log.call Orbf::RulesEngine::GraphvizProjectPrinter.new.print_project(project)
    Orbf::RulesEngine::Log.call "------------------------- solver"
    Orbf::RulesEngine::Log.call Orbf::RulesEngine::GraphvizVariablesPrinter.new.print(solver.variables)
  end

  it "should build problem based on variables" do
    orgs = orgunits_full[0..2]
    solver = build_solver(orgs, dhis2_values)
    problem = solver.build_problem
    expected_problem = JSON.parse(fixture_content(:rules_engine, "problem.json"))
    puts JSON.pretty_generate(problem) if problem != expected_problem
    expect(problem).to eq(expected_problem)
  end

  it "should solve equations" do
    solution = solver.solve!

    expect(solution["county_total_indicators_reported_weighted_for_2016q1"]).to eq(180.0)
    expect(solution["county_total_available_budget_for_fosa_for_2016q1"]).to eq(121_235.0)

    Orbf::RulesEngine::InvoiceCliPrinter.new(solver.variables, solver.solution).print
    exported_values = Orbf::RulesEngine::Dhis2ValuesPrinter.new(solver.variables, solver.solution).print
    expect(exported_values).to include(
      dataElement: "dhis2_dataelement_id_fosa_indicators_reported_weighted",
      orgUnit:     "14",
      period:      "2016Q1",
      value:       9,
      comment:     "facility_fosa_indicators_reported_weighted_for_14_and_2016q1"
    )
  end

  it "should build package variables" do
    variable = Orbf::RulesEngine::PackageVariablesBuilder.new(project.packages.first, orgunits_full, period).to_variables.last
    expect(variable.key).to eq("facility_fosa_available_budget_for_20_and_2016q1")

    expect(variable.expression).to eq("facility_fosa_indicators_reported_weighted_for_county_for_20_and_2016q1 * max(facility_act1_actual_regional_bonus_for_20_and_2016q1, facility_act2_actual_regional_bonus_for_20_and_2016q1, facility_act3_actual_regional_bonus_for_20_and_2016q1, facility_act4_actual_regional_bonus_for_20_and_2016q1, facility_act5_actual_regional_bonus_for_20_and_2016q1, facility_act6_actual_regional_bonus_for_20_and_2016q1, facility_act7_actual_regional_bonus_for_20_and_2016q1, facility_act8_actual_regional_bonus_for_20_and_2016q1, facility_act9_actual_regional_bonus_for_20_and_2016q1)")
  end

  it "should build formula variables" do
    variable = Orbf::RulesEngine::ActivityFormulaVariablesBuilder.new(project.packages.first, orgunits_full, period).to_variables.last
    expect(variable.key).to eq("facility_act9_actual_regional_bonus_for_20_and_2016q1")
    expect(variable.expression).to eq("facility_act9_regional_bonus_level_1_for_country_id_and_2016q1")
  end

  def build_solver(orgs, dhis2_values)
    pyramid = Orbf::RulesEngine::Pyramid.new(
      org_units:          orgs,
      org_unit_groups:    org_unit_groups,
      org_unit_groupsets: [groupset]
    )
    package_arguments = Orbf::RulesEngine::ResolveArguments.new(
      project:          project,
      pyramid:          pyramid,
      orgunit_ext_id:   orgs[0].ext_id,
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
