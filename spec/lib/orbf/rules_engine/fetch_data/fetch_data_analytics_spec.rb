RSpec.describe Orbf::RulesEngine::FetchDataAnalytics do
  let(:dhis2_connection) do
    ::Dhis2::Client.new(
      url:      "https://play.dhis2.org/2.28",
      user:     "admin",
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

  let(:package) do
    double(:package, activities: activities)
  end

  let(:activities) do
    [
      Orbf::RulesEngine::Activity.with(
        name:            "activity_code",
        activity_code:   "activity_code",
        activity_states: [
          Orbf::RulesEngine::ActivityState.new_constant(
            state:   "price",
            name:    "activity_code_price",
            formula: "10"
          ), Orbf::RulesEngine::ActivityState.new_data_element(
            state:  :achieved,
            ext_id: "dhis2_de_1",
            name:   "act1_achieved",
            origin: "analytics"
          ), Orbf::RulesEngine::ActivityState.new_indicator(
            state:      :achieved,
            ext_id:     "dhis2_indic_1",
            name:       "act1_achieved",
            origin:     "analytics",
            expression: "whocares"
          )

        ]
      )
    ]
  end

  let(:package_arguments) do
    [
      Orbf::RulesEngine::PackageArguments.with(
        periods:          %w[201601 201602 201603],
        orgunits:         Orbf::RulesEngine::OrgUnits.new(
          orgunits: [orgunit_1], package: package
        ),
        datasets_ext_ids: [],
        package:          package
      ),
      Orbf::RulesEngine::PackageArguments.with(
        periods:          %w[2016Q1 2015Q1],
        orgunits:         Orbf::RulesEngine::OrgUnits.new(
          orgunits: [orgunit_2], package: package
        ),
        datasets_ext_ids: [],
        package:          package
      )
    ]
  end

  let(:fetch_data) { described_class.new(dhis2_connection, package_arguments) }

  it "combines all arguments and fetch data in one call" do
    WebMock::Config.instance.query_values_notation = :flat_array

    request = stub_request(:get, "https://play.dhis2.org/2.28/api/analytics?dimension=dx:dhis2_de_1%3Bdhis2_indic_1&dimension=ou:1%3B2&dimension=pe:201601")
              .to_return(status: 200, body: JSON.pretty_generate(
                "rows" => [
                  ["dhis2_de_1", orgunit_1.ext_id, "2016Q1", "1.4"]
                ]
              ), headers: {})

    values = fetch_data.call

    WebMock::Config.instance.query_values_notation = nil

    expect(request).to have_been_made.once

    expect(values).to eq([{ "attributeOptionCombo" => "default",
                            "categoryOptionCombo"  => "default",
                            "dataElement"          => "dhis2_de_1",
                            "orgUnit"              => "1",
                            "period"               => "2016Q1",
                            "value"                => "1.4" }])
  end
end
