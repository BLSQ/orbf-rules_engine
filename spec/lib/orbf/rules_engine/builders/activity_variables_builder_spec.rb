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

  let(:project) {Orbf::RulesEngine::Project.new({})}

  context "null values" do
    let(:activities) do
      [
        Orbf::RulesEngine::Activity.with(
          name:            "act1",
          activity_code:   "act1",
          activity_states: [
            Orbf::RulesEngine::ActivityState.new_data_element(
              state:  :achieved,
              ext_id: "dhis2_act1_achieved",
              name:   "act1_achieved",
              origin: "dataValueSets"
            ),
            Orbf::RulesEngine::ActivityState.new_data_element(
              state:  :target,
              ext_id: "dhis2_act1_target",
              name:   "act1_target",
              origin: "dataValueSets"
            )
          ]
        )
      ]
    end

    let(:package) do
      Orbf::RulesEngine::Package.new(
        project:    project,
        code:       :facility,
        kind:       :single,
        frequency:  :quarterly,
        activities: activities,
        rules:      [
          Orbf::RulesEngine::Rule.new(
            kind:     :activity,
            formulas: [
              Orbf::RulesEngine::Formula.new(
                "percent_achieved",
                "if(achieved_is_null=1,target,achieved)"
              )
            ]
          )
        ]
      )
    end

    let(:dhis2_values) do
      [
        { "dataElement" => "dhis2_act1_achieved", "categoryOptionCombo" => "default", "value" => "0", "period" => "2016Q1", "orgUnit" => "1", "comment" => "African Foundation Baptist-0" }
      ]
    end

    let(:expected_vars) do
      [
        Orbf::RulesEngine::Variable.with(
          period:         "2016Q1",
          key:            "facility_act1_achieved_for_1_and_2016q1",
          expression:     "0",
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
          key:            "facility_act1_achieved_is_null_for_1_and_2016q1",
          expression:     "0",
          state:          "achieved_is_null",
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
          key:            "facility_act1_achieved_is_null_for_2_and_2016q1",
          expression:     "1",
          state:          "achieved_is_null",
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
          expression:     "0",
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
        )
      ]
    end

    it "registers extra variables for null values" do
      result = described_class.new(package, orgunits, dhis2_values).convert("2016Q1")
      expect(result).to eq_vars(expected_vars)
    end
  end

  context "simple case" do
    let(:activities) do
      [
        Orbf::RulesEngine::Activity.with(
          name:            "act1",
          activity_code:   "act1",
          activity_states: [
            Orbf::RulesEngine::ActivityState.new_data_element(
              state:  :achieved,
              ext_id: "dhis2_act1_achieved",
              name:   "act1_achieved",
              origin: "dataValueSets"
            ),
            Orbf::RulesEngine::ActivityState.new_data_element(
              state:  :target,
              ext_id: "dhis2_act1_target",
              name:   "act1_target",
              origin: "dataValueSets"
            )
          ]
        ),
        Orbf::RulesEngine::Activity.with(
          name:            "act2",
          activity_code:   "act2",
          activity_states: [
            Orbf::RulesEngine::ActivityState.new_data_element(
              state:  :achieved,
              ext_id: "dhis2_act2_achieved",
              name:   "act2_achieved",
              origin: "dataValueSets"
            )
          ]
        )
      ]
    end

    let(:package) do
      Orbf::RulesEngine::Package.new(
        project:    project,
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
        ),
        Orbf::RulesEngine::Variable.with(
          period:         "2016Q1",
          key:            "facility_act2_target_for_1_and_2016q1",
          expression:     "0",
          state:          "target",
          activity_code:  "act2",
          type:           "activity",
          orgunit_ext_id: orgunits.first.ext_id,
          formula:        nil,
          package:        package,
          payment_rule:   nil
        ),
        Orbf::RulesEngine::Variable.with(
          period:         "2016Q1",
          key:            "facility_act2_target_for_2_and_2016q1",
          expression:     "0",
          state:          "target",
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
          name:            "act1",
          activity_code:   "act1",
          activity_states: [
            Orbf::RulesEngine::ActivityState.new_data_element(
              state:  :cap,
              ext_id: "dhis2_act1_cap",
              name:   "act1_target",
              origin: "dataValueSets"
            )
          ]
        )
      ]
    end

    let(:package) do
      Orbf::RulesEngine::Package.new(
        project:    project,
        code:       :facility,
        kind:       :single,
        frequency:  :quarterly,
        activities: activities,
        rules:      [
          Orbf::RulesEngine::Rule.new(
            kind:     :activity,
            formulas: [
              Orbf::RulesEngine::Formula.new("allowed",  "cap_level_1", ""),
              Orbf::RulesEngine::Formula.new("allowed2", "cap_level_2", "")
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
          key:            "facility_act1_cap_level_1_for_country_id_and_2016",
          expression:     "33",
          state:          "cap_level_1",
          activity_code:  "act1",
          type:           "activity",
          orgunit_ext_id: "country_id",
          formula:        nil,
          package:        package,
          payment_rule:   nil
        ), Orbf::RulesEngine::Variable.with(
          period:         "2016",
          key:            "facility_act1_cap_level_2_for_county_id_and_2016",
          expression:     "12",
          state:          "cap_level_2",
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


  context "parent case with frequency" do
    let(:activities) do
      [
        Orbf::RulesEngine::Activity.with(
          name:            "act1",
          activity_code:   "act1",
          activity_states: [
            Orbf::RulesEngine::ActivityState.new_data_element(
              state:  :cap,
              ext_id: "dhis2_act1_cap",
              name:   "act1_target",
              origin: "dataValueSets"
            )
          ]
        )
      ]
    end

    let(:package) do
      Orbf::RulesEngine::Package.new(
        project:    project,
        code:       :facility,
        kind:       :single,
        frequency:  :quarterly,
        activities: activities,
        rules:      [
          Orbf::RulesEngine::Rule.new(
            kind:     :activity,
            formulas: [
              Orbf::RulesEngine::Formula.new("allowed", "cap_level_2_quarterly", "")
            ]
          )
        ]
      )
    end

    let(:dhis2_values) do
      [
        { "dataElement" => "dhis2_act1_cap", "categoryOptionCombo" => "default", "value" => "33", "period" => "2016Q1", "orgUnit" => "country_id", "comment" => "" },
        { "dataElement" => "dhis2_act1_cap", "categoryOptionCombo" => "default", "value" => "12", "period" => "2016Q1", "orgUnit" => "county_id",  "comment" => "" }
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
        ),
        Orbf::RulesEngine::Variable.with(
          period:         "2016",
          key:            "facility_act1_cap_level_2_quarterly_for_county_id_and_2016",
          expression:     "12",
          state:          "cap_level_2_quarterly",
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


  context "zone main orgunit case" do
    let(:activities) do
      [
        Orbf::RulesEngine::Activity.with(
          name:            "act1",
          activity_code:   "act1",
          activity_states: [
            Orbf::RulesEngine::ActivityState.new_data_element(
              state:  :cap,
              ext_id: "dhis2_act1_cap",
              name:   "act1_target",
              origin: "dataValueSets"
            )
          ]
        )
      ]
    end

    let(:package) do
      Orbf::RulesEngine::Package.new(
        project:         project,
        code:            :facility,
        kind:            :zone,
        frequency:       :quarterly,
        activities:      activities,
        groupset_ext_id: "zonegroupid",
        rules:           [
          Orbf::RulesEngine::Rule.new(
            kind:     :activity,
            formulas: [
              Orbf::RulesEngine::Formula.new("allowed", "cap_zone_main_orgunit", "")
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
          key:            "facility_act1_cap_zone_main_orgunit_for_1_and_2016",
          expression:     "0",
          state:          "cap_zone_main_orgunit",
          activity_code:  "act1",
          type:           "activity",
          orgunit_ext_id: "1",
          formula:        nil,
          package:        package,
          payment_rule:   nil
        )
      ]
    end

    it "registers activity_variables" do
      result = described_class.new(
        package,
        Orbf::RulesEngine::OrgUnits.new(orgunits: orgunits, package: package),
        dhis2_values
      ).convert("2016")
      expect(result).to eq_vars(expected_vars)
    end
  end

  context "data elements with multiple category combo" do
    let(:activities) do
      [
        Orbf::RulesEngine::Activity.with(
          name:            "act1",
          activity_code:   "act1",
          activity_states: [
            Orbf::RulesEngine::ActivityState.new_data_element(
              state:  :cap,
              ext_id: "dhis2_act1_cap",
              name:   "act1_cap",
              origin: "dataValueSets"
            )
          ]
        )
      ]
    end

    let(:package) do
      Orbf::RulesEngine::Package.new(
        project:    project,
        code:       :facility,
        kind:       :single,
        frequency:  :quarterly,
        activities: activities,
        rules:      [
          Orbf::RulesEngine::Rule.new(
            kind:     :activity,
            formulas: [
              Orbf::RulesEngine::Formula.new("allowed", "cap", ""),
              Orbf::RulesEngine::Formula.new(
                "cap_check",
                "if(cap_is_null=1,4,7)"
              )
            ]
          )
        ]
      )
    end

    describe "sums category combos values and remove nil one" do
      let(:dhis2_values) do
        [
          { "dataElement" => "dhis2_act1_cap", "categoryOptionCombo" => "1to4", "value" => "33", "period" => "2016", "orgUnit" => "2", "comment" => "" },
          { "dataElement" => "dhis2_act1_cap", "categoryOptionCombo" => "5to20", "value" => nil, "period" => "2016", "orgUnit" => "2", "comment" => "" },
          { "dataElement" => "dhis2_act1_cap", "categoryOptionCombo" => "morethan20", "value" => "12", "period" => "2016", "orgUnit" => "2", "comment" => "" }
        ]
      end

      let(:expected_vars) do
        [
          Orbf::RulesEngine::Variable.with(
            period:         "2016",
            key:            "facility_act1_cap_for_2_and_2016",
            expression:     "33 + 12",
            state:          "cap",
            activity_code:  "act1",
            type:           "activity",
            orgunit_ext_id: "2",
            formula:        nil,
            package:        package,
            payment_rule:   nil
          ),
          Orbf::RulesEngine::Variable.with(
            period:         "2016",
            key:            "facility_act1_cap_is_null_for_2_and_2016",
            expression:     "0",
            state:          "cap_is_null",
            activity_code:  "act1",
            type:           "activity",
            orgunit_ext_id: "2",
            formula:        nil,
            package:        package,
            payment_rule:   nil
          )
        ]
      end

      it "registers activity_variables" do
        result = described_class.new(
          package,
          Orbf::RulesEngine::OrgUnits.new(orgunits: [orgunits.last], package: package),
          dhis2_values
        ).convert("2016")
        expect(result).to eq_vars(expected_vars)
      end
    end

    describe "default to 0 when all dhis2 values are nil" do
      let(:dhis2_values) do
        [
          { "dataElement" => "dhis2_act1_cap", "categoryOptionCombo" => "1to4", "value" => nil, "period" => "2016", "orgUnit" => "2", "comment" => "" },
          { "dataElement" => "dhis2_act1_cap", "categoryOptionCombo" => "5to20", "value" => nil, "period" => "2016", "orgUnit" => "2", "comment" => "" },
          { "dataElement" => "dhis2_act1_cap", "categoryOptionCombo" => "morethan20", "value" => nil, "period" => "2016", "orgUnit" => "2", "comment" => "" }
        ]
      end

      let(:expected_vars) do
        [
          Orbf::RulesEngine::Variable.with(
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
          ),
          Orbf::RulesEngine::Variable.with(
            period:         "2016",
            key:            "facility_act1_cap_is_null_for_2_and_2016",
            expression:     "1",
            state:          "cap_is_null",
            activity_code:  "act1",
            type:           "activity",
            orgunit_ext_id: "2",
            formula:        nil,
            package:        package,
            payment_rule:   nil
          )
        ]
      end

      it "registers activity_variables" do
        result = described_class.new(
          package,
          Orbf::RulesEngine::OrgUnits.new(orgunits: [orgunits.last], package: package),
          dhis2_values
        ).convert("2016")
        expect(result).to eq_vars(expected_vars)
      end
    end
  end

  context "package quarterly based " do
    let(:activities) do
      [
        Orbf::RulesEngine::Activity.with(
          name:            "act1",
          activity_code:   "act1",
          activity_states: [
            Orbf::RulesEngine::ActivityState.new_data_element(
              state:  :cap,
              ext_id: "dhis2_act1_cap",
              name:   "act1_cap",
              origin: "dataValueSets"
            )
          ]
        )
      ]
    end

    let(:package) do
      Orbf::RulesEngine::Package.new(
        project:    project,
        code:       :facility,
        kind:       :single,
        frequency:  :quarterly,
        activities: activities,
        rules:      [
          Orbf::RulesEngine::Rule.new(
            kind:     :activity,
            formulas: [
              Orbf::RulesEngine::Formula.new("allowed", "cap", ""),
              Orbf::RulesEngine::Formula.new(
                "cap_check",
                "if(cap_is_null=1,4,7)"
              )
            ]
          )
        ]
      )
    end

    describe "sums category combos values and remove nil one" do
      let(:dhis2_values) do
        [
          { "dataElement" => "dhis2_act1_cap", "categoryOptionCombo" => "1to4", "value" => "33", "period" => "2016", "orgUnit" => "2", "comment" => "" },
          { "dataElement" => "dhis2_act1_cap", "categoryOptionCombo" => "5to20", "value" => nil, "period" => "2016", "orgUnit" => "2", "comment" => "" },
          { "dataElement" => "dhis2_act1_cap", "categoryOptionCombo" => "morethan20", "value" => "12", "period" => "2016", "orgUnit" => "2", "comment" => "" }
        ]
      end

      let(:expected_vars) do
        [
          Orbf::RulesEngine::Variable.with(
            period:         "2016",
            key:            "facility_act1_cap_for_2_and_2016",
            expression:     "33 + 12",
            state:          "cap",
            activity_code:  "act1",
            type:           "activity",
            orgunit_ext_id: "2",
            formula:        nil,
            package:        package,
            payment_rule:   nil
          ),
          Orbf::RulesEngine::Variable.with(
            period:         "2016",
            key:            "facility_act1_cap_is_null_for_2_and_2016",
            expression:     "0",
            state:          "cap_is_null",
            activity_code:  "act1",
            type:           "activity",
            orgunit_ext_id: "2",
            formula:        nil,
            package:        package,
            payment_rule:   nil
          )
        ]
      end

      it "registers activity_variables" do
        result = described_class.new(
          package,
          Orbf::RulesEngine::OrgUnits.new(orgunits: [orgunits.last], package: package),
          dhis2_values
        ).convert("2016")
        expect(result).to eq_vars(expected_vars)
      end
    end

    describe "default monthly values when quarterly requested" do
      let(:dhis2_values) do
        [
          { "dataElement" => "dhis2_act1_cap", "categoryOptionCombo" => "default", "value" => 1, "period" => "201601", "orgUnit" => "2", "comment" => "" },
          { "dataElement" => "dhis2_act1_cap", "categoryOptionCombo" => "default", "value" => nil, "period" => "201602", "orgUnit" => "2", "comment" => "" },
          { "dataElement" => "dhis2_act1_cap", "categoryOptionCombo" => "default", "value" => 3, "period" => "201603", "orgUnit" => "2", "comment" => "" }
        ]
      end

      describe "when some values" do
        let(:expected_vars) do
          [
            Orbf::RulesEngine::Variable.with(
              period:         "2016Q1",
              key:            "facility_act1_cap_for_2_and_2016q1",
              expression:     "1 + 3",
              state:          "cap",
              activity_code:  "act1",
              type:           "activity",
              orgunit_ext_id: "2",
              formula:        nil,
              package:        package,
              payment_rule:   nil
            ),
            Orbf::RulesEngine::Variable.with(
              period:         "2016Q1",
              key:            "facility_act1_cap_is_null_for_2_and_2016q1",
              expression:     "0",
              state:          "cap_is_null",
              activity_code:  "act1",
              type:           "activity",
              orgunit_ext_id: "2",
              formula:        nil,
              package:        package,
              payment_rule:   nil
            )
          ]
        end

        it "registers activity_variables" do
          result = described_class.new(
            package,
            Orbf::RulesEngine::OrgUnits.new(orgunits: [orgunits.last], package: package),
            dhis2_values
          ).convert("2016Q1")
          expect(result).to eq_vars(expected_vars)
        end
      end

      describe "when null values" do
        let(:expected_vars) do
          [
            Orbf::RulesEngine::Variable.with(
              period:         "2016Q1",
              key:            "facility_act1_cap_for_2_and_2016q1",
              expression:     "0",
              state:          "cap",
              activity_code:  "act1",
              type:           "activity",
              orgunit_ext_id: "2",
              formula:        nil,
              package:        package,
              payment_rule:   nil
            ),
            Orbf::RulesEngine::Variable.with(
              period:         "2016Q1",
              key:            "facility_act1_cap_is_null_for_2_and_2016q1",
              expression:     "1",
              state:          "cap_is_null",
              activity_code:  "act1",
              type:           "activity",
              orgunit_ext_id: "2",
              formula:        nil,
              package:        package,
              payment_rule:   nil
            )
          ]
        end

        it "registers activity_variables" do
          result = described_class.new(
            package,
            Orbf::RulesEngine::OrgUnits.new(orgunits: [orgunits.last], package: package),
            []
          ).convert("2016Q1")
          expect(result).to eq_vars(expected_vars)
        end
      end
    end
  end
end
