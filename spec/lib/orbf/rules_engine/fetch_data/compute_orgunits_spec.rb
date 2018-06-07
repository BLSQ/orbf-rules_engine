
RSpec.describe Orbf::RulesEngine::ComputeOrgunits do
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
    []
  end

  let(:package) do
    Orbf::RulesEngine::Package.new(
      code:                   :facility,
      kind:                   :single,
      activities:             activities,
      frequency:              :quarterly,
      org_unit_group_ext_ids: %w[hf hosp],
      rules:                  [
        Orbf::RulesEngine::Rule.new(
          kind:     :activity,
          formulas: [
            Orbf::RulesEngine::Formula.new(
              "half_price", "price/2"
            )
          ]
        )
      ]
    )
  end

  let(:project) do
    Orbf::RulesEngine::Project.new(
      packages: [package]
    )
  end

  let(:pyramid) do
    Orbf::RulesEngine::Pyramid.new(
      org_units:          org_units,
      org_unit_groups:    org_unit_groups,
      org_unit_groupsets: []
    )
  end

  it "gives all orgunits that can be invoiced per package" do
    expect(pyramid)
    orgunits = Orbf::RulesEngine::ComputeOrgunits.new(project, pyramid, "contracted").call
    expect(orgunits[package.code].map(&:ext_id)).to eq(%w[1 2])
  end
end
