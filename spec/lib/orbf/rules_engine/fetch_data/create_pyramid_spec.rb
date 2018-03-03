
RSpec.describe Orbf::RulesEngine::CreatePyramid do
  include Dhis2Stubs

  let(:dhis2_connection) do
    ::Dhis2::Client.new(
      url:     "https://admin:district@play.dhis2.org/2.28",
      version: "2.28"
    )
  end

  let(:subject) { described_class.new(dhis2_connection) }

  let(:expected_orgunit) do
    Orbf::RulesEngine::OrgUnit.with(
      ext_id:        "Rp268JB6Ne4",
      group_ext_ids: ["f25dqv3Y7Z0"],
      name:          "Adonkia CHP",
      path:          "/ImspTQPwCqd/at6UHUQatSo/qtr8GGlm4gg/Rp268JB6Ne4"
    )
  end

  let(:expected_groupset) do
    Orbf::RulesEngine::OrgUnitGroupset.with(
      ext_id:        "uIuxlbV1vRT",
      group_ext_ids: %w[nlX2VoouN63 jqBqIXoXpfy J40PpdN4Wkk b0EsAxm8Nge],
      name:          "Area"
    )
  end

  it "fetch orgunits and groupsets and build a pyramid out of it" do
    stub_orgunits
    stub_orgunit_groupsets

    pyramid = subject.call

    expect(pyramid.org_unit(expected_orgunit.ext_id)).to eq(expected_orgunit)

    expect(pyramid.groupset(expected_groupset.ext_id)).to eq(expected_groupset)
  end
end
