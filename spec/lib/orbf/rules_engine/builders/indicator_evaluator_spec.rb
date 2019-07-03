# rubocop:disable Lint/InterpolationCheck
RSpec.describe Orbf::RulesEngine::IndicatorEvaluator do
  let(:indicator_ext_id) { "dhis2_act1_achieved" }

  # Helper class, to build up a data_element-hash
  #
  #       Mapper.new("my-element", "some-category-combo", "100").to_h
  #       # =>
  #       {
  #         "dataElement" => "my-element",
  #         "categoryOptionCombo" => "some-category-combo",
  #         "value" => "100",
  #         "period" => "2016Q1",
  #         "orgUnit" => "1"
  #        }
  #
  # element - data-element id
  # coc - category combo, when nil defaults to 'default'
  # value - value to be set
  #
  # Note: period and orgUnit are fixed.
  class Mapper
    attr_reader :element, :coc, :value
    def initialize(element, coc, value)
      @element = element
      @coc = coc || "default"
      @value = value
    end

    def to_h
      { "dataElement"         => @element,
        "categoryOptionCombo" => @coc,
        "value"               => @value,
        "period"              => "2016Q1",
        "orgUnit"             => "1" }
    end
  end

  # Simple factory to build an indicator
  def indicator_with(formula:, ext_id: "dhis2_act1_achieved", state: :achieved)
    Orbf::RulesEngine::ActivityState.new_indicator(
      state:      state,
      ext_id:     ext_id,
      name:       "name_#{ext_id}",
      expression: formula,
      origin:     "dataValueSets"
    )
  end

  # Test if `to_dhis2_values` does what we expect
  #
  # data - An array of Mapper instances (can be a single one as well)
  # indicators - An array of indicators/Orbf::RulesEngine::ActivityState
  # expected - An array of Mapper instances (can be a single one as well)
  #
  # `data` and `expected` will be expanded to a hash similar do the
  # dhis2 hashes for data_elements
  def expect_evaluation(data, indicators, expected, solutions = nil)
    raw_values = [data].flatten.map(&:to_h)
    expected_values = [expected].flatten.map(&:to_h)
    dhis2_values = described_class.new(indicators, raw_values).to_dhis2_values
    expect(dhis2_values).to match_array(expected_values)
    if solutions
      dhis2_values.each_with_index do |dhis2_value, index|
        calc = Orbf::RulesEngine::CalculatorFactory.build(3)
        got = calc.solve("final_value" => dhis2_value["value"])
        expect(got["final_value"]).to eq(solutions[index])
      end
    end
  end

  context "Valid indicator expression" do
    let(:indicators) do
      [
        Orbf::RulesEngine::ActivityState.new_indicator(
          state:      :achieved,
          ext_id:     "dhis2_act1_achieved",
          name:       "act1_achieved",
          expression: '#{dhjgLt7EYmu.se1qWfbtkmx}',
          origin:     "dataValueSets"
        ),
        Orbf::RulesEngine::ActivityState.new_indicator(
          state:      :target,
          ext_id:     "dhis2_act1_target",
          name:       "act1_target",
          expression: '#{dhjgLt7EYmu.se1qWfbtkmx} + #{xtVtnuWBBLB}',
          origin:     "dataValueSets"
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
           "value" => " 33 ", "period" => "2016Q1", "orgUnit" => "1" },
        { "dataElement" => "dhis2_act1_target",   "categoryOptionCombo" => "default",
          "value" => " 33  +  34 ", "period" => "2016Q1", "orgUnit" => "1" },
        { "dataElement" => "dhis2_act1_achieved", "categoryOptionCombo" => "default",
           "value" => " 3 ", "period" => "2016Q1", "orgUnit" => "2" },
        { "dataElement" => "dhis2_act1_target",   "categoryOptionCombo" => "default",
          "value" => " 3  +  24 ", "period" => "2016Q1", "orgUnit" => "2" }
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

    it "handle negative values" do
      expect_evaluation(
        Mapper.new("de2", nil, "-5"),
        [indicator_with(formula: '#{de1.coc1}+#{de2}')],
        Mapper.new(indicator_ext_id, nil, "0+ -5 "),
        [-5]
      )
    end
  end
  context "no data element reference" do
    it "handles constants" do
      expect do
        expect_evaluation(
          Mapper.new("de2", nil, "5"),
          [indicator_with(formula: "10")],
          Mapper.new(indicator_ext_id, nil, "10")
        )
      end.to raise_error(Orbf::RulesEngine::UnsupportedFormulaException)
    end
  end

  context "Under no values" do
    it "computer DHIS2 values" do
      expect_evaluation(
        [],
        nil,
        []
      )
    end

    it "computers indicators without values" do
      indicators = [Orbf::RulesEngine::ActivityState.new_indicator(
        state:      :achieved,
        ext_id:     "dhis2_act1_achieved",
        name:       "act1_achieved",
        expression: '#{dhjgLt7EYmu.se1qWfbtkmx}',
        origin: "dataValueSets"
      )]
      expect_evaluation(
        Mapper.new("not-used-in-expression", "default", "34"),
        indicators,
        Mapper.new("dhis2_act1_achieved", nil, nil)
      )
    end
  end

  context "when partial values" do
    it "computers indicators with partial values : no value for de1.coc1" do
      expect_evaluation(
        Mapper.new("de2", nil, "5"),
        [indicator_with(formula: '#{de1.coc1} + #{de2}')],
        Mapper.new(indicator_ext_id, nil, "0 +  5 ")
      )
    end

    it "computers indicators with partial values : no value for de1.coc1" do
      expect_evaluation(
        Mapper.new("de2", nil, "5"),
        [indicator_with(formula: '#{de1.coc1} + #{de2}')],
        Mapper.new(indicator_ext_id, nil, "0 +  5 "),
        [5]
      )
    end

    it "compute indicators with partial values d2 multiple combos will sum and add parentheses" do
      expect_evaluation(
        [Mapper.new("de2", "coca", "5"), Mapper.new("de2", "cocb", "5")],
        [indicator_with(formula: '#{de1.coc1} + #{de2}')],
        [Mapper.new(indicator_ext_id, nil, "0 + ( 5 + 5 )")]
      )
    end

    it "compute indicators with partial values d2 multiple combos will sum and add parentheses" do
      expect_evaluation(
        [Mapper.new("de2", "coca", "5"), Mapper.new("de2", "cocb", nil)],
        [indicator_with(formula: '#{de1.coc1} + #{de2}')],
        Mapper.new(indicator_ext_id, nil, "0 + ( 5 + 0 )")
      )
    end

    it "compute indicators with partial values" do
      expect_evaluation(
        Mapper.new("de1", "coc1", "34"),
        [indicator_with(formula: '#{de1.coc1} + #{de2}')],
        Mapper.new(indicator_ext_id, "default", " 34  + 0")
      )
    end

    it "compute indicators with multiple occurrences in expression" do
      expect_evaluation(
        [Mapper.new("de1", "coc1", "34"), Mapper.new("de2", "coc2", "15")],
        [indicator_with(formula: '#{de1.coc1} + #{de2} - #{de1.coc1} - #{de2}')],
        Mapper.new(indicator_ext_id, "default", " 34  +  15  -  34  -  15 ")
      )
    end

    it "has a nil value for expressions without any matches" do
      expect_evaluation(
        Mapper.new("d1", "coc1", "34"),
        [indicator_with(formula: '#{de1.coc1} + #{de2}')],
        Mapper.new("dhis2_act1_achieved", "default", nil)
      )
    end
  end
end
# rubocop:enable Lint/InterpolationCheck
