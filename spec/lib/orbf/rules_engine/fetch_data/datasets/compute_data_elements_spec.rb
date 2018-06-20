RSpec.describe Orbf::RulesEngine::Datasets::ComputeDataElements do
  let(:activities) do
    [
      Orbf::RulesEngine::Activity.with(
        name:            "act1",
        activity_code:   "act1",
        activity_states: [
          Orbf::RulesEngine::ActivityState.new_constant(
            state:   :active,
            name:    "act1_active",
            formula: "10"
          )
        ]
      )
    ]
  end

  let(:package) do
    Orbf::RulesEngine::Package.new(
      code:                   :facility,
      kind:                   :single,
      activities:             activities,
      frequency:              :monthly,
      org_unit_group_ext_ids: %w[hf hosp],
      rules:                  [
        Orbf::RulesEngine::Rule.new(
          kind:     :activity,
          formulas: [
            Orbf::RulesEngine::Formula.new(
              "no_mapping_half_price", "price/2",
              ""
            ),
            Orbf::RulesEngine::Formula.new(
              "half_price", "price/2",
              "",
              activity_mappings: { "act1" => "de_act1_month" }
            ),
            Orbf::RulesEngine::Formula.new(
              "half_price_quarterl", "price/2",
              "",
              frequency:         "quarterly",
              activity_mappings: { "act1" => "de_act1_quarter" }
            )
          ]
        ),
        Orbf::RulesEngine::Rule.new(
          kind:     :package,
          formulas: [
            Orbf::RulesEngine::Formula.new(
              "no_mapping_half_price", "4",
              ""
            ),
            Orbf::RulesEngine::Formula.new(
              "half_price", "4",
              "",
              single_mapping: "de1_pack_month"
            ),
            Orbf::RulesEngine::Formula.new(
              "half_price_quarterl", "4",
              "",
              frequency:      "quarterly",
              single_mapping: "de2_pack_quarter"
            )
          ]
        )
      ]
    )
  end

  let(:project) do
    Orbf::RulesEngine::Project.new(
      packages:      [package],
      payment_rules: [
        payment_rule
      ]
    )
  end

  let(:payment_rule) do
    Orbf::RulesEngine::PaymentRule.new(
      frequency: :quarterly,
      packages:  [package],
      rule:      Orbf::RulesEngine::Rule.new(
        kind:     :payment,
        formulas: [
          Orbf::RulesEngine::Formula.new(
            "quality_bonus", "1000"
          )
        ]
      )
    )
  end

  it "return data elements used for output" do
    data_elements = described_class.new(project).call

    expected_elements = {
      [payment_rule, "monthly"]   => Set.new(%w[de_act1_month de1_pack_month]),
      [payment_rule, "quarterly"] => Set.new(%w[de_act1_quarter de2_pack_quarter])
    }

    expected_elements.each do |k, _v|
      expect(expected_elements[k]).to eq(data_elements[k])
    end
  end
end
