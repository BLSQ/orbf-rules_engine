RSpec.describe "Packages cross referencies" do
  REFERENCED_DATA_ELEMENT_EXT_ID = "referenced_de_shared_ext_id".freeze

  let(:project) do
    Orbf::RulesEngine::Project.new(
      packages:      [
        referenced_package,
        main_package
      ],
      payment_rules: [],
      dhis2_params:  {
        url:      "http://dhis2.oo",
        user:     "dhis2u",
        password: "dhis2pwd"
      }
    )
  end

  let(:orgunits) do
    [
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "1",
        path:          "country_id/county_id/1",
        name:          "African Foundation Baptist",
        group_ext_ids: ["contracted"]
      )
    ]
  end

  let(:orgunit_groups) do
    [
      Orbf::RulesEngine::OrgUnitGroup.with(
        ext_id: "contracted",
        name:   "C",
        code:   "contracted"
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

  let(:referenced_activities) do
    [
      Orbf::RulesEngine::Activity.with(
        name:            "referenced_act1",
        activity_code:   "referenced_act1",
        activity_states: [
          Orbf::RulesEngine::ActivityState.new_constant(
            state:   :achieved,
            name:    "referenced_act1_achieved",
            formula: "10"
          )
        ]
      )
    ]
  end

  let(:main_activities) do
    [
      Orbf::RulesEngine::Activity.with(
        name:            "m_act1",
        activity_code:   "m_act1",
        activity_states: [
          Orbf::RulesEngine::ActivityState.new_data_element(
            state:  :score,
            ext_id: REFERENCED_DATA_ELEMENT_EXT_ID,
            name:   "referenced_de_shared",
            origin: "dataValueSets"
          )
        ]
      )
    ]
  end
  describe "frequency from package" do
    let(:referenced_package) do
      Orbf::RulesEngine::Package.new(
        code:                        :referenced,
        kind:                        :single,
        frequency:                   :quarterly,
        main_org_unit_group_ext_ids: ["contracted"],
        activities:                  referenced_activities,
        rules:                       [
          Orbf::RulesEngine::Rule.new(
            kind:     :activity,
            formulas: [
              Orbf::RulesEngine::Formula.new(
                "amount", "achieved * 100", ""
              )
            ]
          ),
          Orbf::RulesEngine::Rule.new(
            kind:     :package,
            formulas: [
              Orbf::RulesEngine::Formula.new(
                "referenced_amount", "SUM(%{amount_values})", "", single_mapping: REFERENCED_DATA_ELEMENT_EXT_ID
              )
            ]
          )
        ]
      )
    end

    let(:main_package) do
      Orbf::RulesEngine::Package.new(
        code:                        :main,
        kind:                        :single,
        frequency:                   :quarterly,
        main_org_unit_group_ext_ids: ["contracted"],
        activities:                  main_activities,
        rules:                       [
          Orbf::RulesEngine::Rule.new(
            kind:     :activity,
            formulas: [
              Orbf::RulesEngine::Formula.new(
                "amount", "score * 2", ""
              )
            ]
          ),
          Orbf::RulesEngine::Rule.new(
            kind:     :package,
            formulas: [
              Orbf::RulesEngine::Formula.new(
                "quantity_amount", "SUM(%{amount_values})", "", single_mapping: "final_score"
              )
            ]
          )
        ]
      )
    end

    let(:expected_dhis2_values) do
      [{ dataElement: REFERENCED_DATA_ELEMENT_EXT_ID,
         orgUnit:     "1",
         period:      "2016Q1",
         value:       1000,
         comment:     "referenced_referenced_amount_for_1_and_2016q1" },
       { dataElement: "final_score",
         orgUnit:     "1",
         period:      "2016Q1",
         value:       2000,
         comment:     "main_quantity_amount_for_1_and_2016q1" }]
    end

    it "should links" do
      fetch_and_solve = Orbf::RulesEngine::FetchAndSolve.new(
        project,
        "1",
        "2016Q1",
        pyramid:     pyramid,
        mock_values: []
      )
      fetch_and_solve.call

      expect(fetch_and_solve.solver.build_problem).to eq(
        "main_m_act1_score_for_1_and_2016q1"                 => "referenced_referenced_amount_for_1_and_2016q1",
        "main_m_act1_score_for_1_and_2016"                   => "0",
        "main_m_act1_score_for_1_and_2015july"               => "0",
        "const_referenced_act1_achieved_for_2016q1"          => "10",
        "referenced_referenced_act1_amount_for_1_and_2016q1" => "const_referenced_act1_achieved_for_2016q1 * 100",
        "referenced_referenced_amount_for_1_and_2016q1"      => "SUM(referenced_referenced_act1_amount_for_1_and_2016q1)",
        "main_m_act1_amount_for_1_and_2016q1"                => "main_m_act1_score_for_1_and_2016q1 * 2",
        "main_quantity_amount_for_1_and_2016q1"              => "SUM(main_m_act1_amount_for_1_and_2016q1)"
      )

      expect(fetch_and_solve.exported_values).to eq(expected_dhis2_values)
    end
  end

  describe "frequency from formula" do
    let(:referenced_package) do
      Orbf::RulesEngine::Package.new(
        code:                        :referenced,
        kind:                        :single,
        frequency:                   :monthly,
        main_org_unit_group_ext_ids: ["contracted"],
        activities:                  referenced_activities,
        rules:                       [
          Orbf::RulesEngine::Rule.new(
            kind:     :activity,
            formulas: [
              Orbf::RulesEngine::Formula.new(
                "amount_monthly", "achieved * 100", ""
              ),
              Orbf::RulesEngine::Formula.new(
                "amount", "SUM(%{amount_monthly_current_quarter_values})", "",
                frequency:         "quarterly",
                activity_mappings: {
                  referenced_activities.first.activity_code => REFERENCED_DATA_ELEMENT_EXT_ID
                }
              )
            ]
          )
        ]
      )
    end

    let(:main_package) do
      Orbf::RulesEngine::Package.new(
        code:                        :main,
        kind:                        :single,
        frequency:                   :quarterly,
        main_org_unit_group_ext_ids: ["contracted"],
        activities:                  main_activities,
        rules:                       [
          Orbf::RulesEngine::Rule.new(
            kind:     :activity,
            formulas: [
              Orbf::RulesEngine::Formula.new(
                "amount", "score * 2", ""
              )
            ]
          ),
          Orbf::RulesEngine::Rule.new(
            kind:     :package,
            formulas: [
              Orbf::RulesEngine::Formula.new(
                "quantity_amount", "SUM(%{amount_values})", "", single_mapping: "final_score"
              )
            ]
          )
        ]
      )
    end

    let(:expected_dhis2_values) do
      [{ dataElement: REFERENCED_DATA_ELEMENT_EXT_ID,
         orgUnit:     "1",
         period:      "2016Q1",
         value:       3000,
         comment:     "referenced_referenced_act1_amount_for_1_and_201601" },
       { dataElement: "final_score",
         orgUnit:     "1",
         period:      "2016Q1",
         value:       6000,
         comment:     "main_quantity_amount_for_1_and_2016q1" }]
    end

    it "should links" do
      fetch_and_solve = Orbf::RulesEngine::FetchAndSolve.new(
        project,
        "1",
        "2016Q1",
        pyramid:     pyramid,
        mock_values: []
      )
      fetch_and_solve.call
      # puts JSON.pretty_generate(fetch_and_solve.solver.build_problem)
      expect(fetch_and_solve.solver.build_problem).to eq(
        JSON.parse(JSON.pretty_generate(
                     "main_m_act1_score_for_1_and_2016q1":                         "referenced_referenced_act1_amount_for_1_and_201603",
                     "main_m_act1_score_for_1_and_2016":                           "0",
                     "main_m_act1_score_for_1_and_2015july":                       "0",
                     "const_referenced_act1_achieved_for_201601":                  "10",
                     "referenced_referenced_act1_amount_monthly_for_1_and_201601": "const_referenced_act1_achieved_for_201601 * 100",
                     "referenced_referenced_act1_amount_for_1_and_201601":         "SUM(referenced_referenced_act1_amount_monthly_for_1_and_201601,referenced_referenced_act1_amount_monthly_for_1_and_201602,referenced_referenced_act1_amount_monthly_for_1_and_201603)",
                     "const_referenced_act1_achieved_for_201602":                  "10",
                     "referenced_referenced_act1_amount_monthly_for_1_and_201602": "const_referenced_act1_achieved_for_201602 * 100",
                     "referenced_referenced_act1_amount_for_1_and_201602":         "SUM(referenced_referenced_act1_amount_monthly_for_1_and_201601,referenced_referenced_act1_amount_monthly_for_1_and_201602,referenced_referenced_act1_amount_monthly_for_1_and_201603)",
                     "const_referenced_act1_achieved_for_201603":                  "10",
                     "referenced_referenced_act1_amount_monthly_for_1_and_201603": "const_referenced_act1_achieved_for_201603 * 100",
                     "referenced_referenced_act1_amount_for_1_and_201603":         "SUM(referenced_referenced_act1_amount_monthly_for_1_and_201601,referenced_referenced_act1_amount_monthly_for_1_and_201602,referenced_referenced_act1_amount_monthly_for_1_and_201603)",
                     "main_m_act1_amount_for_1_and_2016q1":                        "main_m_act1_score_for_1_and_2016q1 * 2",
                     "main_quantity_amount_for_1_and_2016q1":                      "SUM(main_m_act1_amount_for_1_and_2016q1)"
                   ))
      )

      expect(fetch_and_solve.exported_values).to eq(expected_dhis2_values)
    end
  end

  describe "quarterly package output referenced by monthly package" do
    let(:referenced_package) do
      Orbf::RulesEngine::Package.new(
        code:                        :referenced,
        kind:                        :single,
        frequency:                   :quarterly,
        main_org_unit_group_ext_ids: ["contracted"],
        activities:                  referenced_activities,
        rules:                       [
          Orbf::RulesEngine::Rule.new(
            kind:     :activity,
            formulas: [
              Orbf::RulesEngine::Formula.new(
                "score", "15", "",
                activity_mappings: {
                  referenced_activities.first.activity_code => REFERENCED_DATA_ELEMENT_EXT_ID
                }
              )
            ]
          )
        ]
      )
    end

    let(:main_package) do
      Orbf::RulesEngine::Package.new(
        code:                        :main,
        kind:                        :single,
        frequency:                   :monthly,
        main_org_unit_group_ext_ids: ["contracted"],
        activities:                  main_activities,
        rules:                       [
          Orbf::RulesEngine::Rule.new(
            kind:     :activity,
            formulas: [
              Orbf::RulesEngine::Formula.new(
                "score_q", "score_quarterly", "",
                frequency:         "quarterly"
              ),
              Orbf::RulesEngine::Formula.new(
                "amount", "score_q + 10", ""
              )
            ]
          ),
          Orbf::RulesEngine::Rule.new(
            kind:     :package,
            formulas: [
              Orbf::RulesEngine::Formula.new(
                "quantity_amount", "SUM(%{amount_values})", "", single_mapping: "final_score"
              )
            ]
          )
        ]
      )
    end
    it "should links" do
      fetch_and_solve = Orbf::RulesEngine::FetchAndSolve.new(
        project,
        "1",
        "2016Q1",
        pyramid:     pyramid,
        mock_values: []
      )
      fetch_and_solve.call

      # puts JSON.pretty_generate(fetch_and_solve.solver.build_problem)

      expect(fetch_and_solve.solver.build_problem).to eq(
        JSON.parse(JSON.pretty_generate(
                     "main_m_act1_score_for_1_and_201601":                "referenced_referenced_act1_score_for_1_and_2016q1",
                     "main_m_act1_score_for_1_and_201602":                "referenced_referenced_act1_score_for_1_and_2016q1",
                     "main_m_act1_score_for_1_and_201603":                "referenced_referenced_act1_score_for_1_and_2016q1",
                     "main_m_act1_score_for_1_and_2016":                  "0",
                     "main_m_act1_score_for_1_and_2015july":              "0",
                     "const_referenced_act1_achieved_for_2016q1":         "10",
                     "referenced_referenced_act1_score_for_1_and_2016q1": "15",
                     "main_m_act1_score_q_for_1_and_201601":              "main_m_act1_score_for_1_and_201601",
                     "main_m_act1_amount_for_1_and_201601":               "main_m_act1_score_q_for_1_and_201601 + 10",
                     "main_quantity_amount_for_1_and_201601":             "SUM(main_m_act1_amount_for_1_and_201601)",
                     "main_m_act1_score_q_for_1_and_201602":              "main_m_act1_score_for_1_and_201602",
                     "main_m_act1_amount_for_1_and_201602":               "main_m_act1_score_q_for_1_and_201602 + 10",
                     "main_quantity_amount_for_1_and_201602":             "SUM(main_m_act1_amount_for_1_and_201602)",
                     "main_m_act1_score_q_for_1_and_201603":              "main_m_act1_score_for_1_and_201603",
                     "main_m_act1_amount_for_1_and_201603":               "main_m_act1_score_q_for_1_and_201603 + 10",
                     "main_quantity_amount_for_1_and_201603":             "SUM(main_m_act1_amount_for_1_and_201603)"
                   ))
      )
    end
  end
end
