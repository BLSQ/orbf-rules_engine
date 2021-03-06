RSpec.describe Orbf::RulesEngine::DecisionVariablesBuilder do
  let(:activities) do
    [
      Orbf::RulesEngine::Activity.with(
        name:            "act1",
        activity_code:   "act1",
        activity_states: [
          Orbf::RulesEngine::ActivityState.new_data_element(
            state:  :active,
            ext_id: "dhis2_act1_active",
            name:   "act1_active",
            origin: "dataValueSets"
          )
        ]
      ),
      Orbf::RulesEngine::Activity.with(
        name:            "act2",
        activity_code:   "act2",
        activity_states: [
          Orbf::RulesEngine::ActivityState.new_data_element(
            state:  :active,
            ext_id: "dhis2_act2_active",
            name:   "act2_active",
            origin: "dataValueSets"
          )
        ]
      )
    ]
  end

  let(:orgunits) do
    [
      Orbf::RulesEngine::OrgUnitWithFacts.with(
        orgunit: Orbf::RulesEngine::OrgUnit.with(
          ext_id:        "1",
          path:          "country_id/county_id/1",
          name:          "African Foundation Baptist",
          group_ext_ids: []
        ),
        facts:   { "level_2" => "county_id" }
      )
    ]
  end

  let(:package) do
    Orbf::RulesEngine::Package.new(
      code:       :facility,
      kind:       :single,
      frequency:  :quarterly,
      activities: activities,
      rules:      [
        Orbf::RulesEngine::Rule.new(
          kind:            :activity,
          formulas:        [],
          decision_tables: [
            Orbf::RulesEngine::DecisionTable.new(%(in:activity_code,in:level_2,out:equity_bonus
                  act1,county_id,1
                  act2,county_id,2
                ), start_period: nil, end_period: nil)
          ]
        )
      ]
    )
  end

  let(:expected_variables) do
    [
      Orbf::RulesEngine::Variable.with(
        period:         "2016Q1",
        key:            "facility_act1_equity_bonus_for_1_and_2016q1",
        expression:     "1",
        state:          "equity_bonus",
        activity_code:  "act1",
        type:           "activity_rule_decision",
        orgunit_ext_id: "1",
        formula:        nil,
        package:        package,
        payment_rule:   nil
      ),

      Orbf::RulesEngine::Variable.with(
        period:         "2016Q1",
        key:            "facility_act2_equity_bonus_for_1_and_2016q1",
        expression:     "2",
        state:          "equity_bonus",
        activity_code:  "act2",
        type:           "activity_rule_decision",
        orgunit_ext_id: "1",
        formula:        nil,
        package:        package,
        payment_rule:   nil
      )
    ]
  end

  let(:builder) do
    Orbf::RulesEngine::DecisionVariablesBuilder.new(
      package,
      Orbf::RulesEngine::OrgUnits.new(orgunits: orgunits, package: package),
      "2016Q1"
    )
  end

  it "build" do
    expect(builder.to_variables).to eq_vars expected_variables
  end

  describe "2 decision tables with periods" do
    let(:package) do
      Orbf::RulesEngine::Package.new(
        code:       :facility,
        kind:       :single,
        frequency:  :quarterly,
        activities: activities,
        rules:      [
          Orbf::RulesEngine::Rule.new(
            kind:            :activity,
            formulas:        [],
            decision_tables: [
              Orbf::RulesEngine::DecisionTable.new(%(in:activity_code,in:level_2,out:equity_bonus
                    act1,county_id,1
                    act2,county_id,2
                  ), start_period: "2020Q1", end_period: "2020Q1"),
              Orbf::RulesEngine::DecisionTable.new(%(in:activity_code,in:level_2,out:equity_bonus
                  act1,county_id,4
                  act2,county_id,8
                ), start_period: "2020Q2", end_period: "2020Q4")

            ]
          )
        ]
      )
    end
    let(:builder2020Q1) do
      Orbf::RulesEngine::DecisionVariablesBuilder.new(
        package,
        Orbf::RulesEngine::OrgUnits.new(orgunits: orgunits, package: package),
        "2020Q1"
      )
    end

    let(:expected_variables_2020Q1) do
      [
        Orbf::RulesEngine::Variable.with(
          period:         "2020Q1",
          key:            "facility_act1_equity_bonus_for_1_and_2020q1",
          expression:     "1",
          state:          "equity_bonus",
          activity_code:  "act1",
          type:           "activity_rule_decision",
          orgunit_ext_id: "1",
          formula:        nil,
          package:        package,
          payment_rule:   nil
        ),

        Orbf::RulesEngine::Variable.with(
          period:         "2020Q1",
          key:            "facility_act2_equity_bonus_for_1_and_2020q1",
          expression:     "2",
          state:          "equity_bonus",
          activity_code:  "act2",
          type:           "activity_rule_decision",
          orgunit_ext_id: "1",
          formula:        nil,
          package:        package,
          payment_rule:   nil
        )
      ]
    end

    let(:builder2020Q2) do
      Orbf::RulesEngine::DecisionVariablesBuilder.new(
        package,
        Orbf::RulesEngine::OrgUnits.new(orgunits: orgunits, package: package),
        "2020Q2"
      )
    end

    let(:expected_variables_2020Q2) do
      [
        Orbf::RulesEngine::Variable.with(
          period:         "2020Q2",
          key:            "facility_act1_equity_bonus_for_1_and_2020q2",
          expression:     "4",
          state:          "equity_bonus",
          activity_code:  "act1",
          type:           "activity_rule_decision",
          orgunit_ext_id: "1",
          formula:        nil,
          package:        package,
          payment_rule:   nil
        ),

        Orbf::RulesEngine::Variable.with(
          period:         "2020Q2",
          key:            "facility_act2_equity_bonus_for_1_and_2020q2",
          expression:     "8",
          state:          "equity_bonus",
          activity_code:  "act2",
          type:           "activity_rule_decision",
          orgunit_ext_id: "1",
          formula:        nil,
          package:        package,
          payment_rule:   nil
        )
      ]
    end

    let(:builder2016Q1) do
      Orbf::RulesEngine::DecisionVariablesBuilder.new(
        package,
        Orbf::RulesEngine::OrgUnits.new(orgunits: orgunits, package: package),
        "2016Q1"
      )
    end

    it "build with first decision table in 2020Q1, first decision table values" do
      expect(builder2020Q1.to_variables).to eq_vars expected_variables_2020Q1
    end
    it "build with first decision table in 2020Q1, second decision table values" do
      expect(builder2020Q2.to_variables).to eq_vars expected_variables_2020Q2
    end

    it "build with first decision table in 2016Q1, no variables" do
      expect(builder2016Q1.to_variables).to eq_vars []
    end
  end
end
