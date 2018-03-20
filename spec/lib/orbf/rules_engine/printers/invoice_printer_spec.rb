
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
          name:   "act1_achieved"
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
    ) end

    it "export values " do
      invoices = described_class.new(
        [variable_total],
        variable_total.key => 31
      ).print
      invoice = invoices.first
      expect(invoices.size).to eq(1)
      expect(invoice.total_items).to eq(
        [
          Orbf::RulesEngine::TotalItem.with(
            formula:      variable_total.formula,
            explanations: %W[31 31 31\n\t],
            value:        31
          )
        ]
      )
    end
  end

end
