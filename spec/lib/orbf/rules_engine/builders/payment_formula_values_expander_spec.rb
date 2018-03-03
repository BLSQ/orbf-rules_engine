
RSpec.describe Orbf::RulesEngine::PaymentFormulaValuesExpander do
  describe "references to cycle quarter values" do
    let(:orgunits) do
      [
        Orbf::RulesEngine::OrgUnit.with(
          ext_id:        "1",
          path:          "country_id/county_id/1",
          name:          "African Foundation Baptist",
          group_ext_ids: []
        )
      ]
    end

    let(:payment_rule) do
      Orbf::RulesEngine::PaymentRule.new(
        code:      "pbf_payment",
        frequency: :monthly,
        packages:  [
        ],
        rule:      Orbf::RulesEngine::Rule.new(
          kind:     "payment",
          formulas: [
            Orbf::RulesEngine::Formula.new(
              "rbf_amount",
              "quality_bonus + quantity_amount"
            ),
            Orbf::RulesEngine::Formula.new(
              "quaterly_quantity_production",
              "SUM(%{rbf_amount_previous_values}, rbf_amount)"
            )
          ]
        )
      )
    end

    it "expands nothing" do
      result = described_class.new(payment_rule_code: payment_rule.code, formula: payment_rule.rule.formulas.first, orgunit: orgunits.first, period: "201601").expand_values
      expect(result).to eq("quality_bonus + quantity_amount")
    end

    it "expands %{..._previous_values} in variables for month 1" do
      result = described_class.new(payment_rule_code: payment_rule.code, formula: payment_rule.rule.formulas.last, orgunit: orgunits.first, period: "201601").expand_values
      expect(result).to eq("SUM(0, rbf_amount)")
    end

    it "expands %{..._previous_values} in variables for month 2" do
      result = described_class.new(payment_rule_code: payment_rule.code, formula: payment_rule.rule.formulas.last, orgunit: orgunits.first, period: "201602").expand_values
      expect(result).to eq("SUM(#{payment_rule.code}_rbf_amount_for_1_and_201601, rbf_amount)")
    end

    it "expands %{..._previous_values} in variables for month 3" do
      result = described_class.new(payment_rule_code: payment_rule.code, formula: payment_rule.rule.formulas.last, orgunit: orgunits.first, period: "201603").expand_values
      expect(result).to eq("SUM(#{payment_rule.code}_rbf_amount_for_1_and_201601, #{payment_rule.code}_rbf_amount_for_1_and_201602, rbf_amount)")
    end
  end
end
