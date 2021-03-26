RSpec.describe Orbf::RulesEngine::PeriodsResolver do
  let(:project) { Orbf::RulesEngine::Project.new({}) }

  let(:quantity_package) do
    Orbf::RulesEngine::Package.new(
      project:    project,
      code:       :quantity,
      kind:       :single,
      frequency:  :monthly,
      activities: [],
      rules:      [
        Orbf::RulesEngine::Rule.new(
          kind:     :activity,
          formulas: [
            Orbf::RulesEngine::Formula.new(
              "quantity_amount", "42"
            ),
            Orbf::RulesEngine::Formula.new(
              "increase",
              "safe_div(achieved,sum(%{achieved_previous_year_same_quarter_monthly_values}/4))"
            )
          ]
        )
      ]
    )
  end

  let(:activities) do
    [
      Orbf::RulesEngine::Activity.with(
        name:            "spread",
        activity_code:   "spread_01",
        activity_states: [
          Orbf::RulesEngine::ActivityState.new_data_element(
            state:                 "achieved",
            ext_id:                "deid",
            name:                  "spread_percentage",
            origin:                "dataValueSets",
            category_combo_ext_id: "default"
          )
        ]
      )
    ]
  end

  let(:quantity_package_with_quarterly_price) do
    Orbf::RulesEngine::Package.new(
      project:    project,
      code:       :quantity,
      kind:       :single,
      frequency:  :monthly,
      activities: activities,
      rules:      [
        Orbf::RulesEngine::Rule.new(
          kind:     :activity,
          formulas: [
            Orbf::RulesEngine::Formula.new(
              "quantity_amount", "42"
            ),
            Orbf::RulesEngine::Formula.new(
              "increase",
              "540 * achieved_level_3_quarterly"
            )
          ]
        )
      ]
    )
  end

  let(:quality_package) do
    Orbf::RulesEngine::Package.new(
      project:    project,
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

  it "resolve periods from package frequency" do
    expect(described_class.new(quality_package, "2016Q1").call).to eq(%w[2016Q1 2016 2015July])
  end

  it "resolve periods from package frequency and activity span _values" do
    expect(described_class.new(quantity_package, "2016Q1").call).to eq(
      %w[201501 201502 201503 201601 201602 201603 2016 2015July]
    )
  end

  it "resolve periods from package frequency and state_level_x_quarterly" do
    expect(described_class.new(quantity_package_with_quarterly_price, "2016Q1").call).to eq(
      %w[201601 201602 201603 2016 2015July 2016Q1]
    )
  end
end
