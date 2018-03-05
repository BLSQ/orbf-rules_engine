

RSpec.describe Orbf::RulesEngine::OrgUnitWithFacts do
  let(:orgunit) do
    Orbf::RulesEngine::OrgUnit.with(
      ext_id:        "1",
      path:          "country_id/county_id/1",
      name:          "OU1",
      group_ext_ids: ["GROUP_1"]
    )
  end

  let(:facts) { { sample: "facts" } }

  let(:orgunit_with_facts) { described_class.new(orgunit: orgunit, facts: facts)}

  it "have facts" do
    expect(orgunit_with_facts.facts).to eq(facts)
  end

  it "delegates to orgunit" do
    expect(orgunit_with_facts.ext_id).to eq(orgunit.ext_id)
  end

  it "falls back to super when method doesn't exist" do
    expect { orgunit_with_facts.mess}.to raise_error(NoMethodError)
  end
end
