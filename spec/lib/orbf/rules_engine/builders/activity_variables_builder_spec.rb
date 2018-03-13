
RSpec.describe Orbf::RulesEngine::ActivityVariablesBuilder do
  let(:orgunits) do
    [
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "1",
        path:          "country_id/county_id/1",
        name:          "African Foundation Baptist",
        group_ext_ids: []
      ),
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "2",
        path:          "country_id/county_id/2",
        name:          "African Foundation Baptist",
        group_ext_ids: []
      )
    ]
  end

  context "simple case" do
    let(:activities) do
      [
        Orbf::RulesEngine::Activity.with(
          activity_code:   "act1",
          activity_states: [
            Orbf::RulesEngine::ActivityState.new_data_element(
              state:  :achieved,
              ext_id: "dhis2_act1_achieved",
              name:   "act1_achieved"
            ),
            Orbf::RulesEngine::ActivityState.new_data_element(
              state:  :target,
              ext_id: "dhis2_act1_target",
              name:   "act1_target"
            )
          ]
        ),
        Orbf::RulesEngine::Activity.with(
          activity_code:   "act2",
          activity_states: [
            Orbf::RulesEngine::ActivityState.new_data_element(
              state:  :achieved,
              ext_id: "dhis2_act2_achieved",
              name:   "act2_achieved"
            )
          ]
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
            kind:     :activity,
            formulas: [
              Orbf::RulesEngine::Formula.new(
                "percent_achieved", "active * safe_div(achieved,target)",
                "% of Target Achieved [B / C], B and C are from activity states"
              ),
              Orbf::RulesEngine::Formula.new(
                "allowed", "if (percent_achieved < 0.75, 0, percent_achieved)",
                "Allowed [E] : should achieve at least 75% and can not go further than the cap"
              )
            ]
          )
        ]
      )
    end

    let(:dhis2_values) do
      [
        { "dataElement" => "dhis2_act1_achieved", "categoryOptionCombo" => "default", "value" => "33", "period" => "2016Q1", "orgUnit" => "1", "comment" => "African Foundation Baptist-0" },
        { "dataElement" => "dhis2_act1_target",   "categoryOptionCombo" => "default", "value" => "34", "period" => "2016Q1", "orgUnit" => "1", "comment" => "African Foundation Baptist-1" },
        { "dataElement" => "dhis2_act2_achieved", "categoryOptionCombo" => "default", "value" => "80", "period" => "2016Q1", "orgUnit" => "1", "comment" => "African Foundation Baptist-2" }
      ]
    end

    let(:expected_vars) do
      [
        Orbf::RulesEngine::Variable.with(
          period:         "2016Q1",
          key:            "facility_act1_achieved_for_1_and_2016q1",
          expression:     "33",
          state:          "achieved",
          activity_code:  "act1",
          type:           "activity",
          orgunit_ext_id: orgunits.first.ext_id,
          formula:        nil,
          package:        package,
          payment_rule:   nil
        ),
        Orbf::RulesEngine::Variable.with(
          period:         "2016Q1",
          key:            "facility_act1_achieved_for_2_and_2016q1",
          expression:     "0",
          state:          "achieved",
          activity_code:  "act1",
          type:           "activity",
          orgunit_ext_id: orgunits.last.ext_id,
          formula:        nil,
          package:        package,
          payment_rule:   nil
        ),
        Orbf::RulesEngine::Variable.with(
          period:         "2016Q1",
          key:            "facility_act1_target_for_1_and_2016q1",
          expression:     "34",
          state:          "target",
          activity_code:  "act1",
          type:           "activity",
          orgunit_ext_id: orgunits.first.ext_id,
          formula:        nil,
          package:        package,
          payment_rule:   nil
        ),
        Orbf::RulesEngine::Variable.with(
          period:         "2016Q1",
          key:            "facility_act1_target_for_2_and_2016q1",
          expression:     "0",
          state:          "target",
          activity_code:  "act1",
          type:           "activity",
          orgunit_ext_id: orgunits.last.ext_id,
          formula:        nil,
          package:        package,
          payment_rule:   nil
        ),
        Orbf::RulesEngine::Variable.with(
          period:         "2016Q1",
          key:            "facility_act2_achieved_for_1_and_2016q1",
          expression:     "80",
          state:          "achieved",
          activity_code:  "act2",
          type:           "activity",
          orgunit_ext_id: orgunits.first.ext_id,
          formula:        nil,
          package:        package,
          payment_rule:   nil
        ),
        Orbf::RulesEngine::Variable.with(
          period:         "2016Q1",
          key:            "facility_act2_achieved_for_2_and_2016q1",
          expression:     "0",
          state:          "achieved",
          activity_code:  "act2",
          type:           "activity",
          orgunit_ext_id: orgunits.last.ext_id,
          formula:        nil,
          package:        package,
          payment_rule:   nil
        )
      ]
    end

    it "registers activity_variables" do
      result = described_class.new(package, orgunits, dhis2_values).convert("2016Q1")
      expect(result).to eq_vars(expected_vars)
    end
  end

  context "parent case" do
    let(:activities) do
      [
        Orbf::RulesEngine::Activity.with(
          activity_code:   "act1",
          activity_states: [
            Orbf::RulesEngine::ActivityState.new_data_element(
              state:  :cap,
              ext_id: "dhis2_act1_cap",
              name:   "act1_target"
            )
          ]
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
            kind:     :activity,
            formulas: [
              Orbf::RulesEngine::Formula.new("allowed",  "cap_level1", ""),
              Orbf::RulesEngine::Formula.new("allowed2", "cap_level2", "")
            ]
          )
        ]
      )
    end

    let(:dhis2_values) do
      [
        { "dataElement" => "dhis2_act1_cap", "categoryOptionCombo" => "default", "value" => "33", "period" => "2016", "orgUnit" => "country_id", "comment" => "" },
        { "dataElement" => "dhis2_act1_cap", "categoryOptionCombo" => "default", "value" => "12", "period" => "2016", "orgUnit" => "county_id",  "comment" => "" }
      ]
    end

    let(:expected_vars) do
      [
        Orbf::RulesEngine::Variable.with(
          period:         "2016",
          key:            "facility_act1_cap_for_1_and_2016",
          expression:     "0",
          state:          "cap",
          activity_code:  "act1",
          type:           "activity",
          orgunit_ext_id: "1",
          formula:        nil,
          package:        package,
          payment_rule:   nil
        ), Orbf::RulesEngine::Variable.with(
          period:         "2016",
          key:            "facility_act1_cap_for_2_and_2016",
          expression:     "0",
          state:          "cap",
          activity_code:  "act1",
          type:           "activity",
          orgunit_ext_id: "2",
          formula:        nil,
          package:        package,
          payment_rule:   nil
        ), Orbf::RulesEngine::Variable.with(
          period:         "2016",
          key:            "facility_act1_cap_level1_for_country_id_and_2016",
          expression:     "33",
          state:          "cap_level1",
          activity_code:  "act1",
          type:           "activity",
          orgunit_ext_id: "country_id",
          formula:        nil,
          package:        package,
          payment_rule:   nil
        ), Orbf::RulesEngine::Variable.with(
          period:         "2016",
          key:            "facility_act1_cap_level2_for_county_id_and_2016",
          expression:     "12",
          state:          "cap_level2",
          activity_code:  "act1",
          type:           "activity",
          orgunit_ext_id: "county_id",
          formula:        nil,
          package:        package,
          payment_rule:   nil
        )
      ]
    end

    it "registers activity_variables" do
      result = described_class.new(package, orgunits, dhis2_values).convert("2016")
      expect(result).to eq_vars(expected_vars)
    end
  end
end
