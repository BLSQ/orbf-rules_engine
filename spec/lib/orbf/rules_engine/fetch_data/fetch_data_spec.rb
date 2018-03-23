
RSpec.describe Orbf::RulesEngine::FetchData do
  let(:dhis2_connection) do
    ::Dhis2::Client.new(
      url:     "https://play.dhis2.org/2.28",
      user: "admin",
      password: "district"
    )
  end

  let(:orgunit_1) do
    Orbf::RulesEngine::OrgUnit.with(
      ext_id:        "1",
      path:          "country_id/county_id/1",
      name:          "OU1",
      group_ext_ids: ["GROUP_1"]
    )
  end

  let(:orgunit_2) do
    Orbf::RulesEngine::OrgUnit.with(
      ext_id:        "2",
      path:          "country_id/county_id/2",
      name:          "OU2",
      group_ext_ids: ["GROUP_1"]
    )
  end

  let(:package_arguments) do
    [
      Orbf::RulesEngine::PackageArguments.with(
        periods:          %w[201601 201602 201603],
        orgunits:         [orgunit_1],
        datasets_ext_ids: %w[dataset1],
        package:          nil
      ),
      Orbf::RulesEngine::PackageArguments.with(
        periods:          %w[2016Q1 2015Q1],
        orgunits:         [orgunit_2],
        datasets_ext_ids: %w[dataset1 dataset2],
        package:          nil
      )
    ]
  end

  let(:fetch_data) { described_class.new(dhis2_connection, package_arguments) }

  it "combines all arguments and fetch data in one call" do
    request = stub_request(:get,
                           [
                             "https://play.dhis2.org/2.28/api/dataValueSets",
                             "?children=false",
                             "&orgUnit=1&orgUnit=2",
                             "&dataSet=dataset1&dataSet=dataset2",
                             "&period=201601&period=201602&period=201603&period=2016Q1&period=2015Q1"
                           ].join)
              .to_return(status: 200, body: JSON.pretty_generate(
                "dataValues" => []
              ), headers: {})

    fetch_data.call

    expect(request).to have_been_made.once
  end
end
