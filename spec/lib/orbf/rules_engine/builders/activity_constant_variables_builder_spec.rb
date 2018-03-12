
RSpec.describe Orbf::RulesEngine::ActivityConstantVariablesBuilder do
  let(:activities) do
    [
      Orbf::RulesEngine::Activity.with(
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

  let(:orgunits) do
    [
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:    "1",
        path:      "country_id/county_id/1",
        name:      "African Foundation Baptist",
        group_ext_ids: []
      )
    ]
  end

  let(:project) { Orbf::RulesEngine::Project.new(packages: [package]) }

  let(:package) do
    Orbf::RulesEngine::Package.new(
      code:       :facility,
      kind:       :single,
      frequency:  :quarterly,
      activities: activities,
      rules:      []
    )
  end

  let(:expected_results) do
    [
      Orbf::RulesEngine::Variable.with(
        key:            "act1_active_for_2016q1",
        period:         "2016Q1",
        expression:     "10",
        type:           "activity_constant",
        state:          "active",
        activity_code:  "act1",
        orgunit_ext_id: nil,
        formula:        nil,
        package:        package,
        payment_rule:   nil
      )
    ]
  end

  it "creates variables from activity state constants" do
    results = described_class.new(project.packages.first, orgunits, "2016Q1").to_variables
    expect(results).to eq_vars(expected_results)
  end
end
