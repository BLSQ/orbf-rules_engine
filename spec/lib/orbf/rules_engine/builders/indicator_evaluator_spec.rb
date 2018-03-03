
# rubocop:disable Lint/InterpolationCheck
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
          expression: '#{dhjgLt7EYmu.se1qWfbtkmx}+#{xtVtnuWBBLB}'
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
          "value" => "67", "period" => "2016Q1", "orgUnit" => "1" },
        { "dataElement" => "dhis2_act1_achieved", "categoryOptionCombo" => "default",
           "value" => "3", "period" => "2016Q1", "orgUnit" => "2" },
        { "dataElement" => "dhis2_act1_target",   "categoryOptionCombo" => "default",
          "value" => "27", "period" => "2016Q1", "orgUnit" => "2" }
      ]
    end

    it "computer DHIS2 values" do
      dhis2_values = described_class.new(indicators, in_dhis2_values).to_dhis2_values
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
  end
end
# rubocop:enable Lint/InterpolationCheck