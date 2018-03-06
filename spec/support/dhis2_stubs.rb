module Dhis2Stubs
  def stub_orgunit_groupsets
    stub_request(
      :get,
      [
        "https://play.dhis2.org/2.28/",
        "api/organisationUnitGroupSets",
        "?fields=id,code,shortName,displayName,organisationUnitGroups",
        "&page=1&pageSize=10000"
      ].join
    ).to_return(
      status: 200,
      body:   {
        "pager"                     => {
          "page"      => 1,
          "pageCount" => 1,
          "total"     => 1,
          "pageSize"  => 10_000
        },
        "organisationUnitGroupSets" => [
          {
            "id"                     => "uIuxlbV1vRT",
            "displayName"            => "Area",
            "organisationUnitGroups" => [
              { "id" => "nlX2VoouN63" },
              { "id" => "jqBqIXoXpfy" },
              { "id" => "J40PpdN4Wkk" },
              { "id" => "b0EsAxm8Nge" }
            ]
          }
        ]
      }.to_json
    )
  end

  def stub_orgunit_groups
    stub_request(
      :get,
      ["https://play.dhis2.org/2.28/",
       "api/organisationUnitGroups",
       "?fields=id,code,shortName,displayName",
       "&page=1&pageSize=10000"].join
    ).to_return(
      status: 200,
      body:   {
        "pager"                  => {
          "page"      => 1,
          "pageCount" => 1,
          "total"     => 1,
          "pageSize"  => 10_000
        },
        "organisationUnitGroups" => [
          {
            "id"          => "nlX2VoouN63",
            "displayName" => "Adonkia CHP"
          },
          {
            "id"          => "jqBqIXoXpfy",
            "displayName" => "Adonkia CHP"
          },
          {
            "id"          => "J40PpdN4Wkk",
            "displayName" => "Adonkia CHP"
          },
          {
            "id"          => "b0EsAxm8Nge",
            "displayName" => "Adonkia CHP"
          }
        ]
      }.to_json
    )
  end

  def stub_orgunits
    stub_request(
      :get,
      [
        "https://play.dhis2.org/2.28/",
        "api/organisationUnits",
        "?fields=id,displayName,path,organisationUnitGroups",
        "&page=1&pageSize=10000"
      ].join
    ).to_return(
      status: 200,
      body:   {
        "pager"             => {
          "page"      => 1,
          "pageCount" => 1,
          "total"     => 1,
          "pageSize"  => 10_000
        },
        "organisationUnits" => [
          {
            "id"                     => "Rp268JB6Ne4",
            "path"                   => "/ImspTQPwCqd/at6UHUQatSo/qtr8GGlm4gg/Rp268JB6Ne4",
            "displayName"            => "Adonkia CHP",
            "organisationUnitGroups" => [
              {
                "id" => "f25dqv3Y7Z0"
              }
            ]
          }
        ]
      }.to_json
    )
  end

  def stub_values(values)
    stub_request(:get, "https://play.dhis2.org/2.28/api/dataValueSets?children=false")
      .to_return(status: 200, body: values.to_json)
  end
end
