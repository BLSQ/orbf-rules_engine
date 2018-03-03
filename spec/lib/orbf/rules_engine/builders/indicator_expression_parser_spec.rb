
# rubocop:disable Lint/InterpolationCheck
RSpec.describe Orbf::RulesEngine::IndicatorExpressionParser do
  let(:expression) do
    '#{dhjgLt7EYmu.se1qWfbtkmx}+#{xtVtnuWBBLB}'
  end

  it "parses + signs" do
    indicator_expressions = described_class.parse_expression(expression)
    expect(indicator_expressions).to eq(
      [
        Orbf::RulesEngine::IndicatorExpression.with(
          expression:     '#{dhjgLt7EYmu.se1qWfbtkmx}',
          data_element:   "dhjgLt7EYmu",
          category_combo: "se1qWfbtkmx"
        ),
        Orbf::RulesEngine::IndicatorExpression.with(
          expression:     '#{xtVtnuWBBLB}',
          data_element:   "xtVtnuWBBLB",
          category_combo: nil
        )
      ]
    )
  end

  ["-", "/", "*"].each do |sign|
    it "rejects expression wirh #{sign} signs" do
      expression = ['#{dhjgLt7EYmu.se1qWfbtkmx}', sign, '#{xtVtnuWBBLB}'].join
      expect { described_class.parse_expression(expression) }.to raise_error(
        Orbf::RulesEngine::UnsupportedFormulaException,
        ["Unsupported syntax '",
         sign,
         "' in ",
         "'#{expression}'"].join
      )
    end
  end
end
# rubocop:enable Lint/InterpolationCheck