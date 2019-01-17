RSpec.describe Orbf::RulesEngine::IndicatorEvaluator do
  context "Valid indicator expression" do
    let(:indicators) do
      [
        Orbf::RulesEngine::ActivityState.new_indicator(
          state:      :achieved,
          ext_id:     "dhis2_act1_achieved",
          name:       "act1_achieved",
          expression: '#{dhjgLt7EYmu.se1qWfbtkmx}'
        ),
        Orbf::RulesEngine::ActivityState.new_indicator(
          state:      :target,
          ext_id:     "dhis2_act1_target",
          name:       "act1_target",
          expression: '#{dhjgLt7EYmu.se1qWfbtkmx} + #{xtVtnuWBBLB}'
        )
      ]
    end

    let(:in_dhis2_values) do
      [
        { "dataElement" => "xtVtnuWBBLB", "categoryOptionCombo" => "default",
          "value" => "34", "period" => "2016Q1", "orgUnit" => "1" },
        { "dataElement" => "dhjgLt7EYmu", "categoryOptionCombo" => "se1qWfbtkmx",
          "value" => "33", "period" => "2016Q1", "orgUnit" => "1" },
        { "dataElement" => "xtVtnuWBBLB", "categoryOptionCombo" => "default",
          "value" => "24", "period" => "2016Q1", "orgUnit" => "2" },
        { "dataElement" => "dhjgLt7EYmu", "categoryOptionCombo" => "se1qWfbtkmx",
          "value" => "3", "period" => "2016Q1", "orgUnit" => "2" }
      ]
    end

    let(:expected_dhis2_values) do
      [
        { "dataElement" => "dhis2_act1_achieved", "categoryOptionCombo" => "default",
           "value" => "33", "period" => "2016Q1", "orgUnit" => "1" },
        { "dataElement" => "dhis2_act1_target",   "categoryOptionCombo" => "default",
          "value" => "33 + 34", "period" => "2016Q1", "orgUnit" => "1" },
        { "dataElement" => "dhis2_act1_achieved", "categoryOptionCombo" => "default",
           "value" => "3", "period" => "2016Q1", "orgUnit" => "2" },
        { "dataElement" => "dhis2_act1_target",   "categoryOptionCombo" => "default",
          "value" => "3 + 24", "period" => "2016Q1", "orgUnit" => "2" }
      ]
    end

    it "computer DHIS2 values" do
      dhis2_values = described_class.new(indicators, in_dhis2_values).to_dhis2_values
      expect(dhis2_values).to match_array(expected_dhis2_values)
    end

    it "doesn't duplicate dhis2_values when indicators pass twice" do
      dhis2_values = described_class.new(indicators + indicators, in_dhis2_values).to_dhis2_values
      expect(dhis2_values).to match_array(expected_dhis2_values)
    end

    it "return empty values from empty DHIS2 values" do
      dhis2_values = described_class.new(indicators, []).to_dhis2_values
      expect(dhis2_values).to match_array([])
    end
  end

  context "Under no values" do
    it "computer DHIS2 values" do
      dhis2_values = described_class.new(nil, []).to_dhis2_values
      expect(dhis2_values).to match_array([])
    end

    it "computers indicators without values" do
      indicators = [Orbf::RulesEngine::ActivityState.new_indicator(
        state:      :achieved,
        ext_id:     "dhis2_act1_achieved",
        name:       "act1_achieved",
        expression: '#{dhjgLt7EYmu.se1qWfbtkmx}'
      )]
      raw_values = [
        { "dataElement" => "xtVtnuWBBLB", "categoryOptionCombo" => "default",
          "value" => "34", "period" => "2016Q1", "orgUnit" => "1" }
      ]
      dhis2_values = described_class.new(indicators, raw_values).to_dhis2_values

      expected = { "dataElement" => "dhis2_act1_achieved", "categoryOptionCombo" => "default",
        "value" => "0", "period" => "2016Q1", "orgUnit" => "1" }
      expect(dhis2_values).to match_array([expected])
    end
  end

  context "when partial values" do
    let(:indicators) do
      [Orbf::RulesEngine::ActivityState.new_indicator(
        state:      :achieved,
        ext_id:     "dhis2_act1_achieved",
        name:       "act1_achieved",
        expression: '#{de1.coc1} + #{de2}'
      )]
    end
    it "computers indicators with partial values : no value for de1.coc1" do
      raw_values = [
        { "dataElement" => "de2", "categoryOptionCombo" => "default",
          "value" => "5", "period" => "2016Q1", "orgUnit" => "1" }
      ]
      dhis2_values = described_class.new(indicators, raw_values).to_dhis2_values

      expect(dhis2_values).to match_array(
        [
          { "dataElement" => "dhis2_act1_achieved", "categoryOptionCombo" => "default",
            "value" => "0 + 5", "period" => "2016Q1", "orgUnit" => "1" }
        ]
      )
    end

    it "compute indicators with partial values d2 multiple combos will sum and add parentheses" do
      raw_values = [
        { "dataElement" => "de2", "categoryOptionCombo" => "coca",
          "value" => "5", "period" => "2016Q1", "orgUnit" => "1" },
        { "dataElement" => "de2", "categoryOptionCombo" => "cocb",
          "value" => "5", "period" => "2016Q1", "orgUnit" => "1" }
      ]
      dhis2_values = described_class.new(indicators, raw_values).to_dhis2_values

      expect(dhis2_values).to match_array(
        [
          { "dataElement" => "dhis2_act1_achieved", "categoryOptionCombo" => "default",
            "value" => "0 + ( 5 + 5 )", "period" => "2016Q1", "orgUnit" => "1" }
        ]
      )
    end

    it "compute indicators with partial values" do
      raw_values = [
        { "dataElement" => "de1", "categoryOptionCombo" => "coc1",
          "value" => "34", "period" => "2016Q1", "orgUnit" => "1" }
      ]
      dhis2_values = described_class.new(indicators, raw_values).to_dhis2_values

      expect(dhis2_values).to match_array(
        [
          { "dataElement" => "dhis2_act1_achieved", "categoryOptionCombo" => "default",
            "value" => "34 + 0", "period" => "2016Q1", "orgUnit" => "1" }
        ]
      )
    end

    it "compute indicators with partial values" do
      raw_values = [
        { "dataElement" => "d1", "categoryOptionCombo" => "coc1",
          "value" => "34", "period" => "2016Q1", "orgUnit" => "1" }
      ]

      dhis2_values = described_class.new(indicators, raw_values).to_dhis2_values

      # ??? 0 + 0 or nil or nothing dataValue at all ?
      expect(dhis2_values).to match_array(
        [
          { "dataElement" => "dhis2_act1_achieved", "categoryOptionCombo" => "default",
            "value" => nil, "period" => "2016Q1", "orgUnit" => "1" }
        ]
      )
    end
  end
end
# rubocop:enable Lint/InterpolationCheck
