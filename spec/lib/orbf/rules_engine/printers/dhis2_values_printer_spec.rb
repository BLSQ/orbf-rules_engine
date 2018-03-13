
RSpec.describe Orbf::RulesEngine::Dhis2ValuesPrinter do
  let(:orgunit) do
    Orbf::RulesEngine::OrgUnit.with(
      ext_id:        "1",
      path:          "country_id/county_id/1",
      name:          "African Foundation Baptist",
      group_ext_ids: []
    )
  end

  let(:activity) do
    Orbf::RulesEngine::Activity.with(
      activity_code:   "act1",
      activity_states: [
        Orbf::RulesEngine::ActivityState.new_data_element(
          state:  :achieved,
          ext_id: "dhis2_act1_achieved",
          name:   "act1_achieved"
        )
      ]
    )
  end

  describe "when no variable" do
    it "export no values" do
      expect(described_class.new([], {}).print).to eq([])
    end
  end

  describe "when package rule variable" do
    describe "and NO mapping configured " do
      let(:variable_without_mapping) do
        build_variable(nil)
      end
      it "export no values" do
        result_values = described_class.new(
          [variable_without_mapping],
          variable_without_mapping.key => 1.5
        ).print

        expect(result_values).to eq([])
      end
    end

    describe "and mapping configured " do
      let(:data_element_id) { "dhis2_data_element_id" }
      let(:variable_with_mapping) do
        build_variable(data_element_id)
      end
      it "export values " do
        result_values = described_class.new(
          [variable_with_mapping],
          variable_with_mapping.key => 1.5
        ).print

        expect(result_values).to eq(
          [
            {
              dataElement: data_element_id,
              orgUnit:     "1",
              period:      "201601",
              value:       1.5,
              comment:     variable_with_mapping.key
            }
          ]
        )
      end
    end

    def build_variable(single_mapping)
      package = build_package(single_mapping)

      Orbf::RulesEngine::Variable.with(
        key:            "quality_score_for_1_and_201601",
        period:         "201601",
        expression:     "31",
        type:           :package_rule,
        state:          "quality_score",
        activity_code:  nil,
        orgunit_ext_id: "1",
        formula:        package.rules.first.formulas.first,
        package:        package,
        payment_rule:   nil
      )
    end

    def build_package(single_mapping)
      Orbf::RulesEngine::Package.new(
        code:       :quantity,
        kind:       :single,
        frequency:  :quarterly,
        activities: [],
        rules:      [
          Orbf::RulesEngine::Rule.new(
            kind:     :package,
            formulas: [
              Orbf::RulesEngine::Formula.new(
                "quality_score", "31", "",
                single_mapping: single_mapping
              )
            ]
          )
        ]
      )
    end
  end

  describe "when activity variable" do
    let(:activity_variable_with_mapping) do
      build_activity_variable(
        activity.activity_code => "dhis2_data_element_id_act1"
      )
    end

    let(:activity_variable_without_mapping) do
      build_activity_variable(nil)
    end

    describe "and NO mapping configured " do
      it "export no values" do
        result_values = described_class.new(
          [activity_variable_without_mapping],
          activity_variable_without_mapping.key => 1.5
        ).print
        expect(result_values).to eq([])
      end
    end

    describe " and mapping configured " do
      it "export decimal that are actually integer as integer" do
        expect_exported_value(activity_variable_with_mapping, 15.0, 15)
      end

      it "export decimal as decimal" do
        expect_exported_value(activity_variable_with_mapping, 15.0001, 15.0001)
      end

      def expect_exported_value(variable, solution_value, expected_value)
        result_values = described_class.new(
          [variable],
          variable.key => solution_value
        ).print
        expect(result_values).to eq(
          [
            {
              dataElement: "dhis2_data_element_id_act1",
              orgUnit:     "1",
              period:      "2016Q1",
              value:       expected_value,
              comment:     variable.key
            }
          ]
        )
      end
    end

    def build_activity_variable(activity_mappings)
      package = build_package(activity_mappings)

      Orbf::RulesEngine::Variable.with(
        period:         "2016Q1",
        key:            "act1_achieved_for_1_and_2016q1",
        expression:     "33",
        state:          "achieved",
        activity_code:  "act1",
        type:           :activity,
        orgunit_ext_id: orgunit.ext_id,
        formula:        package.rules.first.formulas.first,
        package:        package,
        payment_rule:   nil
      )
    end

    def build_package(activity_mappings)
      Orbf::RulesEngine::Package.new(
        code:       :quantity,
        kind:       :single,
        frequency:  :quarterly,
        activities: [],
        rules:      [
          Orbf::RulesEngine::Rule.new(
            kind:     :activity,
            formulas: [
              Orbf::RulesEngine::Formula.new(
                "quality_score", "31", "",
                activity_mappings: activity_mappings
              )
            ]
          )
        ]
      )
    end
  end
end
