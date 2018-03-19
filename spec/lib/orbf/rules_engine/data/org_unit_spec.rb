

RSpec.describe Orbf::RulesEngine::OrgUnit do
  let(:orgunit) do
    build_org_unit("1")
  end
  let(:same_orgunit) do
    build_org_unit("1")
  end
  let(:diff_orgunit) do
    build_org_unit("2")
  end

  it "should filter org unit" do
    uniq_orgunit = [orgunit, same_orgunit].uniq
    expect(uniq_orgunit.size).to eq(1)
    expect(uniq_orgunit.first).to equal(orgunit)
  end

  describe "#parent_ext_ids" do
    it "returns array of ids" do
      expect(orgunit.parent_ext_ids).to eq(%w[country_id county_id 1])
    end
  end

  def build_org_unit(ext_id)
    Orbf::RulesEngine::OrgUnit.with(
      ext_id:        ext_id,
      path:          "/country_id/county_id/#{ext_id}",
      name:          "OU1",
      group_ext_ids: ["GROUP_1"]
    )
  end
end
