
RSpec.describe Orbf::RulesEngine::FetchData do
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
    double(:package, activities: [])
  end

  let(:package_arguments) do
    [
      Orbf::RulesEngine::PackageArguments.with(
        periods:          %w[201601 201602 201603],
        orgunits:         Orbf::RulesEngine::OrgUnits.new(
          orgunits: [orgunit_1], package: package
        ),
        datasets_ext_ids: %w[dataset1],
        package:          package
      ),
      Orbf::RulesEngine::PackageArguments.with(
        periods:          %w[2016Q1 2015Q1],
        orgunits:         Orbf::RulesEngine::OrgUnits.new(
          orgunits: [orgunit_2], package: package
        ),
        datasets_ext_ids: %w[dataset1 dataset2],
        package:          package
      )
    ]
  end

  let(:fetch_data) { described_class.new(dhis2_connection, package_arguments) }

  let(:expected_url) do
    [
      "https://play.dhis2.org/2.28/api/dataValueSets",
      "?children=false",
      "&orgUnit=1&orgUnit=2&orgUnit=country_id&orgUnit=county_id",
      "&dataSet=dataset1&dataSet=dataset2",
      "&period=2015Q1&period=201601&period=201602&period=201603&period=2016Q1"
    ].join
  end

  it "combines all arguments and fetch data in one call" do
    request = stub_request(:get, expected_url)
              .to_return(status: 200, body: JSON.pretty_generate(
                "dataValues" => []
              ), headers: {})

    fetch_data.call

    expect(request).to have_been_made.once
  end

  context "data cleaning" do
    let(:ok_value) do
      {
        "value":                  "I'm ok",
        "data_element":           "fHV12Didd5R",
        "period":                 "201712",
        "org_unit":               "k2SI9SSS33I",
        "category_option_combo":  "HllvX50cXC0",
        "attribute_option_combo": "HllvX50cXC0",
        "stored_by":              "dd",
        "created":                "2018-04-18T14:33:50.000+0000",
        "last_updated":           "2018-04-30T10:26:24.371+0000",
        "comment":                "form-azeaze by d@d.be",
        "follow_up":              false
      }
    end

    let(:nil_value) do
      {
        "data_element":           "fHV12Didd5R",
        "period":                 "201712",
        "org_unit":               "k2SI9SSS33I",
        "category_option_combo":  "HllvX50cXC0",
        "attribute_option_combo": "HllvX50cXC0",
        "stored_by":              "dd",
        "created":                "2018-04-18T14:33:50.000+0000",
        "last_updated":           "2018-04-30T10:26:24.371+0000",
        "comment":                "form-azeaze by d@d.be",
        "follow_up":              false
      }
    end

    it "cleans up the null values" do
      stub_request(:get, expected_url)
        .to_return(status: 200, body: JSON.pretty_generate(
          "dataValues" => [
            nil_value,
            ok_value
          ]
        ), headers: {})

      values = fetch_data.call

      expect(values).to eq [
        { "dataElement"          => "fHV12Didd5R",
          "period"               => "201712",
          "orgUnit"              => "k2SI9SSS33I",
          "categoryOptionCombo"  => "HllvX50cXC0",
          "attributeOptionCombo" => "HllvX50cXC0",
          "value"                => "I'm ok",
          "storedBy"             => "dd",
          "origin"               =>"dataValueSets",
          "created"              => "2018-04-18T14:33:50.000+0000",
          "lastUpdated"          => "2018-04-30T10:26:24.371+0000",
          "followUp"             => false }
      ]
    end
  end
end
