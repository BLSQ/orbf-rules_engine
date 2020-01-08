
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
              "safe_div(achieved,sum(%{achieved_previous_year_same_quarter_monthly_values}/4)"
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
end
