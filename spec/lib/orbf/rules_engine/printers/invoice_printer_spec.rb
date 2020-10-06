RSpec.describe Orbf::RulesEngine::InvoicePrinter do
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

  let(:package) do
    Orbf::RulesEngine::Package.new(
      code:       :quantity,
      kind:       :single,
      frequency:  :quarterly,
      activities: [activity],
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
      code:      "pbf_payment",
      frequency: :monthly,
      packages:  [package],
      rule:      Orbf::RulesEngine::Rule.new(
        kind:     "payment",
        formulas: [
          Orbf::RulesEngine::Formula.new(
            "rbf_amount",
            "quality_score * 100"
          )
        ]
      )
    )
  end

  describe "when no variable" do
    it "export no values" do
      expect(described_class.new([], {}).print).to eq([])
    end
  end

  describe "mapping configured " do
    let(:variable_total) do
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

    let(:variable_activity) do
      Orbf::RulesEngine::Variable.with(
        key:            "achieved_for_1_and_201601",
        period:         "201601",
        expression:     "12",
        type:           :activity_rule,
        state:          "achieved",
        activity_code:  activity.activity_code,
        orgunit_ext_id: "1",
        formula:        nil,
        package:        package,
        payment_rule:   nil
      )
    end

    let(:variable_payment) do
      Orbf::RulesEngine::Variable.with(
        key:            "rbf_amount_for_1_and_201601",
        period:         "201601",
        expression:     "120",
        type:           "payment_rule",
        state:          "rbf_amount",
        activity_code:  nil,
        orgunit_ext_id: "1",
        formula:        payment_rule.rule.formulas.first,
        package:        nil,
        payment_rule:   payment_rule
      )
    end

    it "export values " do
      invoices = described_class.new(
        [
          variable_total,
          variable_activity,
          variable_payment
        ],
        variable_total.key    => 31,
        variable_activity.key => 12,
        variable_payment.key  => 120
      ).print
      invoice = invoices.first
      payment_invoice = invoices.last
      expect(invoices.size).to eq(2)

      expect(payment_invoice.activity_items).to eq([])
      expect(payment_invoice.total_items.first.to_h).to eq(
        key:          "rbf_amount_for_1_and_201601",
        formula:      variable_payment.formula,
        explanations: ["quality_score * 100", "120", "120\n\t"],
        value:        120,
        not_exported: false
      )

      expect(invoice.activity_items.first.to_h).to eq(
        Orbf::RulesEngine::ActivityItem.with(
          activity:   activity,
          solution:   { "achieved"=>12 },
          problem:    { "achieved"=>"12" },
          substitued: { "achieved"=>"12" },
          variables:  [variable_total, variable_activity]
        ).to_h
      )

      expect(invoice.activity_items.first.input?("achieved")).to eq true
      expect(invoice.activity_items.first.output?("achieved")).to eq false

      expect(invoice.headers).to eq(["achieved"])
      expect(invoice.inspect).to eq("Invoice(package 201601 1 quantity)")
      expect(invoice.total_items.inspect).to eq('[TotalItem(quality_score ["31", "31", "31\n\t"])]')

      expect(invoice.total_items).to eq(
        [
          Orbf::RulesEngine::TotalItem.with(
            formula:      variable_total.formula,
            explanations: %W[31 31 31\n\t],
            value:        31,
            not_exported: false
          )
        ]
      )
    end
  end
end
