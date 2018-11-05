
RSpec.describe Orbf::RulesEngine::SolverFactory do
  let(:orgunits) do
    [
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "1",
        path:          "country_id/county_id/1",
        name:          "African Foundation Baptist",
        group_ext_ids: ["Group1"]
      ),
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "2",
        path:          "country_id/county_id/2",
        name:          "African Foundation Baptist",
        group_ext_ids: ["Group2"]
      )
    ]
  end

  let(:fake_package_builder) { double "p_builder", to_variables: [] }

  def action(project, package_arguments)
    allow(Orbf::RulesEngine::PeriodIterator).to receive(:each_periods).and_yield("2016Q1")
    described_class.new(project, package_arguments, [], "2016Q1", package_builders: [fake_package_builder]).new_solver
  end

  context "iterates over proper package and org units" do
    it "takes both packages and org units" do
      project = build_project(
        engine_version: 1,
        packages:       [
          build_package(%w[Group1 Group2]),
          build_package(%w[Group1 Group2])
        ]
      )

      package_arguments = [
        Orbf::RulesEngine::PackageArguments.with(
          periods:          ["2016Q1"],
          orgunits:         Orbf::RulesEngine::OrgUnits.new(orgunits: orgunits, package: project.packages[0]),
          datasets_ext_ids: [],
          package:          project.packages[0]
        ),
        Orbf::RulesEngine::PackageArguments.with(
          periods:          ["2016Q1"],
          orgunits:         Orbf::RulesEngine::OrgUnits.new(orgunits: orgunits, package: project.packages[1]),
          datasets_ext_ids: [],
          package:          project.packages[1]
        )
      ].index_by(&:package)

      expect_args(project.packages[0], [orgunits[0], orgunits[1]], "2016Q1")
      expect_args(project.packages[1], [orgunits[0], orgunits[1]], "2016Q1")

      action(project, package_arguments)
    end
  end

  def build_project(engine_version:, packages:)
    Orbf::RulesEngine::Project.new(
      engine_version: engine_version,
      packages:       packages,
      payment_rules:  [
        Orbf::RulesEngine::PaymentRule.new(
          frequency: :quarterly,
          packages:  packages,
          rule:      Orbf::RulesEngine::Rule.new(
            kind:     :payment,
            formulas: [
              Orbf::RulesEngine::Formula.new(
                "quality_bonus", "1000"
              )
            ]
          )
        )
      ]
    )
  end

  def build_package(main_org_unit_group_ext_ids)
    Orbf::RulesEngine::Package.new(
      code:                   :facility,
      kind:                   :single,
      frequency:              :monthly,
      main_org_unit_group_ext_ids: Array(main_org_unit_group_ext_ids),
      rules:                  [
        Orbf::RulesEngine::Rule.new(
          kind:     :activity,
          formulas: [
            Orbf::RulesEngine::Formula.new("percent_achieved", "active * safe_div(achieved,target)", "")
          ]
        )
      ]
    )
  end

  def expect_args(package, ous, period)
    expect(fake_package_builder).to receive(:new).once.with(
      package,
      ous,
      period
    ).and_return(fake_package_builder)
  end
end
