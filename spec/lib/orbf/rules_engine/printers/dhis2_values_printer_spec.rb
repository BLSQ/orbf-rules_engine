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
      name:            "act1",
      activity_code:   "act1",
      activity_states: [
        Orbf::RulesEngine::ActivityState.new_data_element(
          state:  :achieved,
          ext_id: "dhis2_act1_achieved",
          name:   "act1_achieved",
          origin: "dataValueSets"
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
          { variable_without_mapping.key => 1.5 }
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
          { variable_with_mapping.key => 1.5 }
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

    describe "and mapping configured with default combos " do
      let(:data_element_id) { "dhis2_data_element_id" }
      let(:variable_with_mapping) do
        build_variable(data_element_id)
      end
      it "export values " do
        result_values = described_class.new(
          [variable_with_mapping],
          { variable_with_mapping.key => 1.5 },
          default_category_option_combo_ext_id:  "coc_id",
          default_attribute_option_combo_ext_id: "aoc_id"
        ).print

        expect(result_values).to eq(
          [
            {
              dataElement:          data_element_id,
              orgUnit:              "1",
              period:               "201601",
              value:                1.5,
              comment:              variable_with_mapping.key,
              categoryOptionCombo:  "coc_id",
              attributeOptionCombo: "aoc_id"
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
        activity_mappings: {
          activity.activity_code => "dhis2_data_element_id_act1"
        }
      )
    end

    let(:activity_variable_without_mapping) do
      build_activity_variable({})
    end

    describe "and NO mapping configured " do
      it "export no values" do
        result_values = described_class.new(
          [activity_variable_without_mapping],
          { activity_variable_without_mapping.key => 1.5 }
        ).print
        expect(result_values).to eq([])
      end
    end

    describe " and mapping configured " do
      it "export decimal that are actually integer as integer" do
        expect_exported_value(activity_variable_with_mapping, 15.0, 15, "2016Q1")
      end

      it "export decimal as decimal" do
        expect_exported_value(activity_variable_with_mapping, 15.0001, 15.0001, "2016Q1")
      end
    end

    describe " and mapping and frequency configured and remove duplicates" do
      let(:var1) do
        build_activity_variable(
          activity_mappings: {
            activity.activity_code => "dhis2_data_element_id_act1"
          },
          frequency:         "monthly"
        )
      end

      let(:var2) do
        build_activity_variable(
          activity_mappings: {
            activity.activity_code => "dhis2_data_element_id_act1"
          },
          frequency:         "monthly"
        )
      end

      it "export decimal that are actually integer as integer" do
        result_values = described_class.new(
          [var1, var2],
          {var1.key => 15, var2.key => 15}
        ).print
        expect(result_values).to eq(
          [
            {
              dataElement: "dhis2_data_element_id_act1",
              orgUnit:     "1",
              period:      "201603",
              value:       15,
              comment:     var1.key
            }
          ]
        )
      end
    end

    describe " and mapping and exportable_formula_code " do
      let(:variables) do
        build_variables
      end

      it "export nil when export formula code is falsy" do
        activity_variable_with_exportable_formula_code = variables[0]
        exportable_variable = variables[1]

        result_values = described_class.new(
          variables,
          { activity_variable_with_exportable_formula_code.key => 15.0,
          exportable_variable.key                            => false }
        ).print

        expect(result_values).to eq(
          [
            { dataElement: "dhis2_data_element_id_act1",
              orgUnit:     "1",
              period:      "2016Q1",
              value:       nil,
              comment:     "act1_achieved_for_1_and_2016q1" }
          ]
        )
      end

      it "export the value when export formula code is truethy" do
        activity_variable_with_exportable_formula_code = variables[0]
        exportable_variable = variables[1]

        result_values = described_class.new(
          variables,
          { activity_variable_with_exportable_formula_code.key => 15.0,
          exportable_variable.key                            => true }
        ).print

        expect(result_values).to eq(
          [
            { dataElement: "dhis2_data_element_id_act1",
              orgUnit:     "1",
              period:      "2016Q1",
              value:       15,
              comment:     "act1_achieved_for_1_and_2016q1" }
          ]
        )
      end

      def build_variables
        package = build_package(
          activity_mappings: {
            activity.activity_code => "dhis2_data_element_id_act1"
          }
        )
        [
          Orbf::RulesEngine::Variable.with(
            period:                  "2016Q1",
            key:                     "act1_achieved_for_1_and_2016q1",
            expression:              "33",
            state:                   "achieved",
            activity_code:           "act1",
            type:                    :activity,
            orgunit_ext_id:          orgunit.ext_id,
            formula:                 package.rules.first.formulas.first,
            package:                 package,
            payment_rule:            nil,
            exportable_variable_key: "act1_exportable_for_1_and_2016q1"
          ),
          Orbf::RulesEngine::Variable.with(
            period:         "2016Q1",
            key:            "act1_exportable_for_1_and_2016q1",
            expression:     "33",
            state:          "exportable",
            activity_code:  "act1",
            type:           :activity,
            orgunit_ext_id: orgunit.ext_id,
            formula:        package.rules.first.formulas.last,
            package:        package
          )
        ]
      end

      def build_package(options)
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
                  **options
                ),
                Orbf::RulesEngine::Formula.new(
                  "exportable", "1 == 1", ""
                )
              ]
            )
          ]
        )
      end
    end

    describe " and mapping and frequency configured " do
      let(:activity_variable_with_mapping_and_frequency) do
        build_activity_variable(
          activity_mappings: {
            activity.activity_code => "dhis2_data_element_id_act1"
          },
          frequency:         "monthly"
        )
      end

      it "export decimal that are actually integer as integer" do
        expect_exported_value(activity_variable_with_mapping_and_frequency, 15.0, 15, "201603")
      end

      it "export decimal as decimal" do
        expect_exported_value(activity_variable_with_mapping_and_frequency, 15.0001, 15.0001, "201603")
      end
    end

    describe "and mapping configured with category combo" do
      let(:data_element_id) { "dhis2_data_element_id" }
      let(:coc_id) { "specific_coc_id"}
      let(:variable_with_mapping) do
        build_activity_variable(
          activity_mappings: {
            activity.activity_code => "#{data_element_id}.#{coc_id}"
          },
          frequency:         "monthly"
        )
      end

      it "export values " do
        result_values = described_class.new(
          [variable_with_mapping],
          { variable_with_mapping.key => 53 }
        ).print

        expect(result_values).to eq(
          [
            {
              dataElement:          data_element_id,
              orgUnit:              "1",
              period:               "201603",
              value:                53,
              comment:              variable_with_mapping.key,
              categoryOptionCombo:  coc_id
            }
          ]
        )
      end
    end

    def expect_exported_value(variable, solution_value, expected_value, period)
      result_values = described_class.new(
        [variable],
        { variable.key => solution_value }
      ).print
      expect(result_values).to eq(
        [
          {
            dataElement: "dhis2_data_element_id_act1",
            orgUnit:     "1",
            period:      period,
            value:       expected_value,
            comment:     variable.key
          }
        ]
      )
    end

    def build_activity_variable(options)
      package = build_package(options)

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

    def build_package(options)
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
                **options
              )
            ]
          )
        ]
      )
    end
  end
end
