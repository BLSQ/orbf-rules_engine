RSpec.describe Orbf::RulesEngine::OrgunitsResolver do
  def action(main_orgunit)
    described_class.new(package, pyramid, main_orgunit).call.to_a
  end

  let(:matching_groupset_ext_ids) do
    []
  end

  let(:package) do
    Orbf::RulesEngine::Package.new(
      code:                        :quantity,
      kind:                        package_kind,
      frequency:                   :monthly,
      activities:                  [],
      rules:                       [],
      main_org_unit_group_ext_ids: ["GROUP_X"],
      groupset_ext_id:             "GROUPSET_ID",
      matching_groupset_ext_ids:   matching_groupset_ext_ids
    )
  end

  let(:groupset) do
    Orbf::RulesEngine::OrgUnitGroupset.with(
      name:          "groupset",
      ext_id:        "GROUPSET_ID",
      group_ext_ids: %w[GROUP_1 GROUP_2],
      code:          "contracts"
    )
  end

  let(:orgunit1) do
    Orbf::RulesEngine::OrgUnit.with(
      ext_id:        "1",
      path:          "country_id/county_id/1",
      name:          "OU1",
      group_ext_ids: ["GROUP_1"]
    )
  end

  let(:orgunit2) do
    Orbf::RulesEngine::OrgUnit.with(
      ext_id:        "2",
      path:          "country_id/county_id/2",
      name:          "OU2",
      group_ext_ids: ["GROUP_2"]
    )
  end

  let(:orgunit3) do
    Orbf::RulesEngine::OrgUnit.with(
      ext_id:        "3",
      path:          "country_id/county_id/3",
      name:          "OU3",
      group_ext_ids: ["GROUP_3"]
    )
  end

  let(:orgunit4) do
    Orbf::RulesEngine::OrgUnit.with(
      ext_id:        "4",
      path:          "country_id/county_id/4",
      name:          "OU4",
      group_ext_ids: %w[GROUP_X GROUP_1]
    )
  end

  let(:orgunitx) do
    Orbf::RulesEngine::OrgUnit.with(
      ext_id:        "X",
      path:          "country_id/county_id/X",
      name:          "OUX",
      group_ext_ids: ["GROUP_X"]
    )
  end

  let(:pyramid) do
    Orbf::RulesEngine::Pyramid.new(
      org_units:          [orgunit1, orgunit2, orgunit3, orgunit4, orgunitx],
      org_unit_groups:    [],
      org_unit_groupsets: [groupset]
    )
  end

  context "subcontract package" do
    let(:package_kind) { :subcontract }

    it "doesnt return anything if main orgunit not in package's org_unit_group_ext_ids" do
      expect(action(orgunit3)).to eq []
    end

    it "returns main org unit + ous in intersection of its group_ext_ids and the one in the groupset" do
      expect(action(orgunitx)).to eq [orgunitx]
      expect(action(orgunit4)).to eq [orgunit4, orgunit1]
    end
  end

  context "single package" do
    let(:package_kind) { :single }

    it "only matching" do
      expect(action(orgunit4)).to eq [orgunit4]
      expect(action(orgunitx)).to eq [orgunitx]
    end

    it "returns empty array if doesnt belong to package's org_unit_group_ext_ids" do
      expect(action(orgunit3)).to eq []
    end
  end

  context "single package and matching groupset" do
    describe "when correct groupset" do
      let(:package_kind) { :single }
      let(:matching_groupset_ext_ids) { "GROUPSET_ID" }

      it "only matching" do
        expect(action(orgunit4)).to eq [orgunit4]
        expect(action(orgunitx)).to eq [orgunitx]
      end

      it "returns empty array if doesnt belong to package's org_unit_group_ext_ids" do
        expect(action(orgunit3)).to eq []
      end
    end

    describe "when other groupset" do
      let(:package_kind) { :single }
      let(:matching_groupset_ext_ids) { "GROUPSET_other_ID" }

      it "only matching" do
        expect(action(orgunit4)).to eq [orgunit4]
        expect(action(orgunitx)).to eq [orgunitx]
      end

      it "returns empty array if doesnt belong to package's org_unit_group_ext_ids" do
        expect(action(orgunit3)).to eq []
      end
    end
  end

  context "zone/liberia type" do
    let(:package_kind) { :zone }

    it "doesnt return anything if main orgunit not in package's org_unit_group_ext_ids" do
      expect(action(orgunit3)).to eq []
    end

    it "returns main org unit + ous in intersection of its group_ext_ids and the one in the groupset" do
      expect(action(orgunitx)).to eq [orgunitx]
      expect(action(orgunit4)).to eq [orgunit4, orgunit1]
    end
  end

  context "zone/burundi type" do
    let(:package_kind) { :zone }

    let(:package) do
      Orbf::RulesEngine::Package.new(
        code:                        :quantity,
        kind:                        package_kind,
        frequency:                   :monthly,
        activities:                  [],
        rules:                       [],
        main_org_unit_group_ext_ids: ["GROUP_X"],
        groupset_ext_id:             "GROUPSET_ID",
        matching_groupset_ext_ids:   matching_groupset_ext_ids,
        include_main_orgunit:        true
      )
    end

    it "doesnt return anything if main orgunit not in package's org_unit_group_ext_ids" do
      expect(action(orgunit3)).to eq []
    end

    it "returns main org unit + ous in intersection of its group_ext_ids and the one in the groupset" do
      expect(action(orgunitx)).to eq [orgunitx, orgunitx]
    end

    it "returns main org unit + ous in intersection of its group_ext_ids and the one in the groupset" do
      expect(action(orgunit4)).to eq [orgunit4, orgunit1, orgunit4]
    end
  end
end
