
# rubocop:disable Lint/InterpolationCheck
RSpec.describe Orbf::RulesEngine::IndicatorExpressionParser do
  describe 'more complex' do
    {
      '(7/100)*#{rfeqp2kdOGi.VVZyXr4y4Sv}*(45/100)*((11.2/(34.9+11.2))*#{FVJ2v5RgBgL.TfexVpwPBYN}+(34.9/(34.9+11.2))*#{a0i3MXpBmhT.kwyUVixl5ts})' => [
        Orbf::RulesEngine::IndicatorExpression.with(
          expression:     '#{rfeqp2kdOGi.VVZyXr4y4Sv}',
          data_element:   "rfeqp2kdOGi",
          category_combo: "VVZyXr4y4Sv"
        ),
        Orbf::RulesEngine::IndicatorExpression.with(
          expression: '#{FVJ2v5RgBgL.TfexVpwPBYN}',
          data_element: "FVJ2v5RgBgL",
          category_combo: "TfexVpwPBYN"
        ),
        Orbf::RulesEngine::IndicatorExpression.with(
          expression: '#{a0i3MXpBmhT.kwyUVixl5ts}',
          data_element: "a0i3MXpBmhT",
          category_combo: "kwyUVixl5ts"
        )
      ]
    }.each do |expression, expected_expressions|
      it "supports #{expression}" do
        indicator_expressions = described_class.parse_expression(expression)
        expect(indicator_expressions).to eq(expected_expressions)
      end
    end
  end

  ["+", "-", "/", "*"].each do |sign|
    it "rejects expression wirh #{sign} signs" do
      expression = ['#{dhjgLt7EYmu.se1qWfbtkmx}', sign, '#{xtVtnuWBBLB}'].join
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
  end

  describe 'UNSUPPORTED FEATURES' do
    let(:mapping) {
      { "C{" => "C{dhjgLt7EYmu.se1qWfbtkmx}" }
    }

    Orbf::RulesEngine::IndicatorExpressionParser::UNSUPPORTED_FEATURES.each do |unsupported|
      it "does not support #{unsupported}" do
        expression = mapping[unsupported]
        expect { described_class.parse_expression(expression) }.to raise_error(
                                                                     Orbf::RulesEngine::UnsupportedFormulaException,
                                                                     ["Unsupported syntax '",
                                                                      unsupported,
                                                                      "' in ",
                                                                      "'#{expression}'"].join
                                                                   )
      end
    end
  end

end
# rubocop:enable Lint/InterpolationCheck
