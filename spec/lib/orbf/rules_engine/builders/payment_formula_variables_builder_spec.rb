
RSpec.describe Orbf::RulesEngine::PaymentFormulaVariablesBuilder do
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

  let(:quantity_package) do
    Orbf::RulesEngine::Package.new(
      code:       :quantity,
      kind:       :single,
      frequency:  :monthly,
      activities: [],
      rules:      [
        Orbf::RulesEngine::Rule.new(
          kind:     :package,
          formulas: [
            Orbf::RulesEngine::Formula.new(
              "quantity_amount", "42", ""
            )
          ]
        )
      ]
    )
  end

  let(:quality_package) do
    Orbf::RulesEngine::Package.new(
      code:       :quality,
      kind:       :single,
      frequency:  :quarterly,
      activities: [],
      rules:      [
        Orbf::RulesEngine::Rule.new(
          kind:     :package,
          formulas: [
            Orbf::RulesEngine::Formula.new(
              "quality_score", "31", ""
            )
          ]
        )
      ]
    )
  end

  let(:payment_rule) do
    Orbf::RulesEngine::PaymentRule.new(
      frequency: :quarterly,
      code:      "fosa_payment",
      packages:  [
        quality_package,
        quantity_package
      ],
      rule:      Orbf::RulesEngine::Rule.new(
        kind:     :payment,
        formulas: [
          Orbf::RulesEngine::Formula.new(
            "quality_bonus", "(quality_score /100) * quantity_amount", ""
          ),
          Orbf::RulesEngine::Formula.new(
            "rbf_amount", "quality_bonus + quantity_amount", ""
          )
        ]
      )
    )
  end

  describe "everything quarterly" do
    let(:expected_results) do
      [
        Orbf::RulesEngine::Variable.with(
          period:         "2016Q1",
          key:            "fosa_payment_quality_bonus_for_1_and_2016q1",
          expression:     "(quality_quality_score_for_1_and_2016q1 /100) * quantity_quantity_amount_for_1_and_2016q1",
          state:          "quality_bonus",
          type:           "payment_rule",
          activity_code:  nil,
          orgunit_ext_id: orgunits.first.ext_id,
          formula:        payment_rule.rule.formulas.first,
          package:        nil
        ),
        Orbf::RulesEngine::Variable.with(
          period:         "2016Q1",
          key:            "fosa_payment_rbf_amount_for_1_and_2016q1",
          expression:     "fosa_payment_quality_bonus_for_1_and_2016q1 + quantity_quantity_amount_for_1_and_2016q1",
          state:          "rbf_amount",
          type:           "payment_rule",
          activity_code:  nil,
          orgunit_ext_id: orgunits.first.ext_id,
          formula:        payment_rule.rule.formulas.last,
          package:        nil
        )
      ]
    end

    it "quarterly payment combines package output in payment rules formulas and add temp variable for quarterly sum for monthly packages" do
      quantity_package.frequency = "quarterly"
      results = described_class.new(payment_rule, orgunits, "2016Q1").to_variables
      expect(results).to eq_vars(expected_results)
    end
  end

  describe "quantity monthly and quality and payment quarterly" do
    let(:expected_results) do
      [
        Orbf::RulesEngine::Variable.with(
          period:         "2016Q1",
          key:            "fosa_payment_quality_bonus_for_1_and_2016q1",
          expression:     "(quality_quality_score_for_1_and_2016q1 /100) * quantity_quantity_amount_for_1_and_2016q1",
          state:          "quality_bonus",
          type:           "payment_rule",
          activity_code:  nil,
          orgunit_ext_id: orgunits.first.ext_id,
          formula:        payment_rule.rule.formulas.first,
          package:        nil
        ),
        Orbf::RulesEngine::Variable.with(
          period:         "2016Q1",
          key:            "fosa_payment_rbf_amount_for_1_and_2016q1",
          expression:     "fosa_payment_quality_bonus_for_1_and_2016q1 + quantity_quantity_amount_for_1_and_2016q1",
          state:          "rbf_amount",
          type:           "payment_rule",
          activity_code:  nil,
          orgunit_ext_id: orgunits.first.ext_id,
          formula:        payment_rule.rule.formulas.last,
          package:        nil
        ),
        Orbf::RulesEngine::Variable.with(
          period:         "2016Q1",
          key:            "quantity_quantity_amount_for_1_and_2016q1",
          expression:     "SUM(quantity_quantity_amount_for_1_and_201601,quantity_quantity_amount_for_1_and_201602,quantity_quantity_amount_for_1_and_201603)",
          state:          "quantity_amount",
          type:           "payment_rule",
          activity_code:  nil,
          orgunit_ext_id: orgunits.first.ext_id,
          formula:        nil,
          package:        nil
        )

      ]
    end

    it "combines package output in payment rules formulas Re" do
      quantity_package.frequency = "monthly"
      results = described_class.new(payment_rule, orgunits, "2016Q1").to_variables
      expect(results).to eq_vars(expected_results)
    end
  end

  describe "payment and quantity monthly, quality quarterly" do
    let(:expected_results) do
      [
        Orbf::RulesEngine::Variable.with(
          period:         "201601",
          key:            "fosa_payment_quality_bonus_for_1_and_201601",
          expression:     "(quality_quality_score_for_1_and_201601 /100) * quantity_quantity_amount_for_1_and_201601",
          state:          "quality_bonus",
          type:           "payment_rule",
          activity_code:  nil,
          orgunit_ext_id: orgunits.first.ext_id,
          formula:        payment_rule.rule.formulas.first,
          package:        nil
        ),
        Orbf::RulesEngine::Variable.with(
          period:         "201601",
          key:            "fosa_payment_rbf_amount_for_1_and_201601",
          expression:     "fosa_payment_quality_bonus_for_1_and_201601 + quantity_quantity_amount_for_1_and_201601",
          state:          "rbf_amount",
          type:           "payment_rule",
          activity_code:  nil,
          orgunit_ext_id: orgunits.first.ext_id,
          formula:        payment_rule.rule.formulas.last,
          package:        nil
        ),
        Orbf::RulesEngine::Variable.with(
          period:         "201602",
          key:            "fosa_payment_quality_bonus_for_1_and_201602",
          expression:     "(quality_quality_score_for_1_and_201602 /100) * quantity_quantity_amount_for_1_and_201602",
          state:          "quality_bonus",
          type:           "payment_rule",
          activity_code:  nil,
          orgunit_ext_id: orgunits.first.ext_id,
          formula:        payment_rule.rule.formulas.first,
          package:        nil
        ),
        Orbf::RulesEngine::Variable.with(
          period:         "201602",
          key:            "fosa_payment_rbf_amount_for_1_and_201602",
          expression:     "fosa_payment_quality_bonus_for_1_and_201602 + quantity_quantity_amount_for_1_and_201602",
          state:          "rbf_amount",
          type:           "payment_rule",
          activity_code:  nil,
          orgunit_ext_id: orgunits.first.ext_id,
          formula:        payment_rule.rule.formulas.last,
          package:        nil
        ),
        Orbf::RulesEngine::Variable.with(
          period:         "201603",
          key:            "fosa_payment_quality_bonus_for_1_and_201603",
          expression:     "(quality_quality_score_for_1_and_201603 /100) * quantity_quantity_amount_for_1_and_201603",
          state:          "quality_bonus",
          type:           "payment_rule",
          activity_code:  nil,
          orgunit_ext_id: orgunits.first.ext_id,
          formula:        payment_rule.rule.formulas.first,
          package:        nil
        ),
        Orbf::RulesEngine::Variable.with(
          period:         "201603",
          key:            "fosa_payment_rbf_amount_for_1_and_201603",
          expression:     "fosa_payment_quality_bonus_for_1_and_201603 + quantity_quantity_amount_for_1_and_201603",
          state:          "rbf_amount",
          type:           "payment_rule",
          activity_code:  nil,
          orgunit_ext_id: orgunits.first.ext_id,
          formula:        payment_rule.rule.formulas.last,
          package:        nil
        ),
        Orbf::RulesEngine::Variable.with(
          period:         "201601",
          key:            "quality_quality_score_for_1_and_201601",
          expression:     "0",
          state:          "quality_score",
          type:           "payment_rule",
          activity_code:  nil,
          orgunit_ext_id: orgunits.first.ext_id,
          formula:        nil,
          package:        nil
        ),
        Orbf::RulesEngine::Variable.with(
          period:         "201602",
          key:            "quality_quality_score_for_1_and_201602",
          expression:     "0",
          state:          "quality_score",
          type:           "payment_rule",
          activity_code:  nil,
          orgunit_ext_id: orgunits.first.ext_id,
          formula:        nil,
          package:        nil
        ),
        Orbf::RulesEngine::Variable.with(
          period:         "201603",
          key:            "quality_quality_score_for_1_and_201603",
          expression:     "quality_quality_score_for_1_and_2016q1",
          state:          "quality_score",
          type:           "payment_rule",
          activity_code:  nil,
          orgunit_ext_id: orgunits.first.ext_id,
          formula:        nil,
          package:        nil
        )

      ]
    end

    it "combines package output in payment rules formulas" do
      payment_rule.frequency = "monthly"
      quantity_package.frequency = "monthly"

      results = described_class.new(payment_rule, orgunits, "2016Q1").to_variables

      expect(results).to eq_vars(expected_results)
    end
  end

  describe "references to cycle quarter values" do
    let(:payment_rule) do
      Orbf::RulesEngine::PaymentRule.new(
        code:      "fosa_payment",
        frequency: :monthly,
        packages:  [
          quality_package,
          quantity_package
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
              "SUM(%{rbf_amount_previous_values}, rbf_amount )"
            )
          ]
        )
      )
    end

    it "expands %{..._previous_values} in variables for month 1" do
      results = described_class.new(payment_rule, orgunits, "201601").to_variables
      expect(results[1].expression).to eq("SUM(0, #{payment_rule.code}_rbf_amount_for_1_and_201601 )")
    end

    it "expands %{..._previous_values} in variables for month 2" do
      results = described_class.new(payment_rule, orgunits, "201602").to_variables
      expect(results[1].expression).to eq("SUM(#{payment_rule.code}_rbf_amount_for_1_and_201601, #{payment_rule.code}_rbf_amount_for_1_and_201602 )")
    end

    it "expands %{..._previous_values} in variables for month 3" do
      results = described_class.new(payment_rule, orgunits, "201603").to_variables
      expect(results[1].expression).to eq("SUM(#{payment_rule.code}_rbf_amount_for_1_and_201601, #{payment_rule.code}_rbf_amount_for_1_and_201602, #{payment_rule.code}_rbf_amount_for_1_and_201603 )")
    end
  end
end
