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
        )
      ]
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

  def required_package_attrs_for(rule_kind:)
    {
      "zone"          => { kind: :zone, groupset_ext_id: "abc123" },
      "zone_activity" => { kind: :zone, groupset_ext_id: "abc123" }
    }.fetch(rule_kind.to_s, kind: :single)
  end

  describe "#print_packages" do
    rule_kinds = Orbf::RulesEngine::Rule::Kinds.all - [Orbf::RulesEngine::Rule::Kinds::PAYMENT]

    rules = rule_kinds.collect do |kind|
      it "can handle rule of kind #{kind}" do
        rule = Orbf::RulesEngine::Rule.new(
          kind:     kind,
          formulas: [Orbf::RulesEngine::Formula.new(
            "form_for_#{kind}",
            "quantity_act1_verified_for_1_and_201601 * 33",
            "comment_for_#{kind}"
          )]
        )
        package_attrs = {
          code:       :facility,
          kind:       :single,
          frequency:  :quarterly,
          activities: [],
          rules:      [rule]
        }
        package_attrs.merge!(required_package_attrs_for(rule_kind: kind))
        package = Orbf::RulesEngine::Package.new(package_attrs)

        expect(subject.print_packages([package])).to_not be_empty
      end
    end
  end
end
