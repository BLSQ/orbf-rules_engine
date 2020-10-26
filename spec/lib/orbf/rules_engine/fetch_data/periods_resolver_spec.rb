
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
            ),
            Orbf::RulesEngine::Formula.new(
              "increase",
              "safe_div(achieved,sum(%{achieved_last_12_months_window_values})"
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
    previous_year_same_quarter = [
      "201501", "201502", "201503", "201504", "201505"
    ]
    last_12_months = [
      "201603", "201602", "201601", "201512", "201511",
      "201510", "201509", "201508", "201507", "201506",
      "201505", "201504"
    ]
    yearlies = ["2016", "2015July"]
    expected = (previous_year_same_quarter + last_12_months).uniq.sort + yearlies
    expect(described_class.new(quantity_package, "2016Q1").call).to eq(expected)
  end
end
