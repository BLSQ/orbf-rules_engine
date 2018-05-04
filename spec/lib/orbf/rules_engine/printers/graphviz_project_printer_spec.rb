RSpec.describe Orbf::RulesEngine::GraphvizProjectPrinter do


  let(:project) { Orbf::RulesEngine::Project.new(packages: [package]) }

  let(:package) do
    Orbf::RulesEngine::Package.new(
      code:       :facility,
      kind:       :single,
      frequency:  :quarterly,
      activities: activities,
      rules:      [
        Orbf::RulesEngine::Rule.new(
          kind:     :activity,
          formulas: [Orbf::RulesEngine::Formula.new(
            "form_1",
            "quantity_act1_verified_for_1_and_201601 * 33",
            "TODO: work harder"
          )]
        )]
    )
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

  it "simple project" do
    expect(subject.print_project(project).join("\n")).to eq(fixture_content(:rules_engine, :printers, "graphviz_simple.txt"))
  end
end
