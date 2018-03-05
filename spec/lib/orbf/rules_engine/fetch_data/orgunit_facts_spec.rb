

RSpec.describe Orbf::RulesEngine::OrgunitFacts do
  GROUP_PMA_EXT_ID = "GROUP_PMA_EXT_ID".freeze

  let(:org_unit) do
    Orbf::RulesEngine::OrgUnit.with(
      ext_id:        "1",
      path:          "country_id/county_id/1",
      name:          "OU1",
      group_ext_ids: [GROUP_PMA_EXT_ID]
    )
  end

  let(:org_unit_groups) do
    [
      Orbf::RulesEngine::OrgUnitGroup.with(
        ext_id: GROUP_PMA_EXT_ID,
        name:   "PMA",
        code:   "pma"
      ),
      Orbf::RulesEngine::OrgUnitGroup.with(
        ext_id: "GROUP_NO_GROUPSET_EXT_ID",
        name:   "DONTCARE",
        code:   "dontcare"
      )
    ]
  end

  let(:org_unit_groupsets) do
    [
      Orbf::RulesEngine::OrgUnitGroupset.with(
        ext_id:        "pma_groupset_ext_id",
        name:          "PMA/PCA",
        code:          "types",
        group_ext_ids: [GROUP_PMA_EXT_ID, "Group_PCA_EXT_ID"]
      )
    ]
  end

  let(:pyramid) do
    Orbf::RulesEngine::Pyramid.new(
      org_units:          [org_unit],
      org_unit_groups:    org_unit_groups,
      org_unit_groupsets: org_unit_groupsets
    )
  end

  let(:subject) { described_class.new(org_unit, pyramid) }

  it "calculates all facts" do
    expect(subject.to_facts).to eq(
      "groupset_code_types" => "pma",
      "level"               => "3",
      "level_1"             => "country_id",
      "level_2"             => "county_id",
      "level_3"             => "1"
    )
  end
end
