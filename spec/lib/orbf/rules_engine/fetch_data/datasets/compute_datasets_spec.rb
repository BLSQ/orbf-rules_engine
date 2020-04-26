RSpec.describe Orbf::RulesEngine::Datasets do
  let(:org_units) do
    [
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "1",
        path:          "country_id/county_id/1",
        name:          "African Foundation Baptist",
        group_ext_ids: %w[contracted hf]
      ),
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "2",
        path:          "country_id/county_id/2",
        name:          "African Foundation Baptist",
        group_ext_ids: %w[contracted hosp]
      ),
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "3",
        path:          "country_id/county_id/3",
        name:          "African Foundation Baptist",
        group_ext_ids: %w[hf]
      ),
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "4",
        path:          "country_id/county_id/4",
        name:          "African Foundation Baptist",
        group_ext_ids: %w[contracted nomatchingpackage]
      )
    ]
  end

  let(:org_unit_groups) do
    [
      Orbf::RulesEngine::OrgUnitGroup.with(
        ext_id: "contracted",
        name:   "contracted entities",
        code:   "contracted"
      ),
      Orbf::RulesEngine::OrgUnitGroup.with(
        ext_id: "hf",
        name:   "health facitilities",
        code:   "hf"
      ),
      Orbf::RulesEngine::OrgUnitGroup.with(
        ext_id: "hosp",
        name:   "hosptial",
        code:   "hosp"
      )

    ]
  end

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
      main_org_unit_group_ext_ids: %w[hf hosp],
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
              activity_mappings: { "act1" => "de_act1_month.coc" }
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
      code:      "test_pay",
      frequency: :quarterly,
      packages:  [package],
      rule:      Orbf::RulesEngine::Rule.new(
        kind:     "payment",
        formulas: [
          Orbf::RulesEngine::Formula.new(
            "quality_bonus", "1000"
          )
        ]
      )
    )
  end

  let(:pyramid) do
    Orbf::RulesEngine::Pyramid.new(
      org_units:          org_units,
      org_unit_groups:    org_unit_groups,
      org_unit_groupsets: []
    )
  end

  describe Orbf::RulesEngine::Datasets::ComputeDataElements do
    it "return data elements used for output" do
      data_elements = described_class.new(project).call

      expected_elements = {
        [payment_rule, "monthly"]   => Set.new(%w[de_act1_month de1_pack_month]),
        [payment_rule, "quarterly"] => Set.new(%w[de_act1_quarter de2_pack_quarter])
      }

       #<Set: {"de_act1_month.coc", "de1_pack_month"}>
       #<Set: {"de_act1_month", "de1_pack_month"}>
      expected_elements.each do |k, _v|
        expect(expected_elements[k]).to eq(data_elements[k])
      end
    end
  end
  describe Orbf::RulesEngine::Datasets::ComputeOrgunits do
    it "gives all orgunits that can be invoiced per package" do
      orgunits = described_class.new(project, pyramid, "contracted").call
      expect(orgunits[package.code].map(&:ext_id)).to eq(%w[1 2])
    end
  end

  describe Orbf::RulesEngine::Datasets::ComputeDatasets do
    it "combines data elements and orgunits" do
      datasets = described_class.new(project: project, pyramid: pyramid, group_ext_id: "contracted").call
      expect(datasets.size).to eq(2)
      dataset = datasets.first
      expect(dataset.frequency).to eq("quarterly")
      expect(dataset.payment_rule_code).to eq("test_pay")
      expect(dataset.data_elements).to eq(%w[de_act1_quarter de2_pack_quarter])
      expect(dataset.orgunits.map(&:ext_id)).to eq(%w[1 2])
    end
  end
end
