RSpec.describe Orbf::RulesEngine::ContractService do
  def stub_contract_program
    stub_request(:get, "https://play.dhis2.org/api/sqlViews/DHIS2ALLEVENTSQLVIEWID/data.json?paging=false&var=programId:DHIS2CONTRACTPROGRAMID")
      .to_return(status: 200, body: fixture_content(:dhis2, "contract_raw_events.json"))
    stub_request(:get, "https://play.dhis2.org/api/programs/DHIS2CONTRACTPROGRAMID?fields=id,name,programStages%5BprogramStageDataElements%5BdataElement%5Bid,name,code,optionSet%5Bid,name,code,options%5Bid,code,name%5D%5D%5D%5D&paging=false")
      .to_return(status: 200, body: fixture_content(:dhis2, "contract_program.json"))
    end

  let(:contract_service) do
    Orbf::RulesEngine::ContractService.new(
      program_id:            "DHIS2CONTRACTPROGRAMID",
      all_event_sql_view_id: "DHIS2ALLEVENTSQLVIEWID",
      dhis2_connection:      Dhis2::Client.new(dhis2_params),
      calendar:              ::Orbf::RulesEngine::GregorianCalendar.new
    )
  end

  let(:dhis2_params) do
    {
      url:      "https://play.dhis2.org",
      user:     "admin",
      password: "district"
    }
  end

  it "works" do
    stub_contract_program

    contracts = contract_service.find_all

    expect(contracts.size).to eq(5)

    expect(contracts.first.to_h).to eq(
      {
        id:            "OgVbqGV2WMH",
        from_period:   "201806",
        end_period:    "202112",
        org_unit_id:   "1",
        org_unit_name: "CSI A",
        field_values:  {
          "contract_end_date"   => "2021-12-31",
          "contract_location"   => "GROUP_RURAL_CODE",
          "contract_start_date" => "2018-06-01",
          "contract_type"       => "GROUP_CSI_1_CODE",
          "date"                => nil,
          "id"                  => "OgVbqGV2WMH",
          "org_unit"            => { "id" => "1", "name" => "CSI A", "path" => nil }
        }
      }
    )
  end

  it "should synchronize based on events" do
    stub_contract_program

    requests = []
    stub_request(:put, "https://play.dhis2.org/api/organisationUnitGroups/").to_return(->(request) { requests.append(JSON.parse(request.body)); { body: "{}" } })

    stub_groups_load
    contract_service.synchronize_groups("2018Q3")

    results = requests.map { |group| [group["code"], group["organisationUnits"].map { |ou| ou["id"] }] }.to_h

    expect(results).to eq(
      {
        "GROUP_CSI_1_CODE"      => ["1"],
        "GROUP_CSI_2_CODE"      => ["2"],
        "GROUP_HD_CODE"         => [],
        "GROUP_PROVINCE_CODE"   => [],
        "GROUP_PURCHASE_1_CODE" => [],
        "GROUP_PURCHASE_2_CODE" => [],
        "GROUP_RURAL_CODE"      => ["1"],
        "GROUP_URBAN_CODE"      => ["2"],
        "contracted"            => %w[1 2 3 X province_id],
        "non-contracted"        => []
      }
    )
  end

  it "should synchronize based on events and put all to non-contracted since really overdue contracts" do
    stub_contract_program

    requests = []
    stub_request(:put, "https://play.dhis2.org/api/organisationUnitGroups/").to_return(->(request) { requests.append(JSON.parse(request.body)); { body: "{}" } })

    stub_groups_load

    contract_service.synchronize_groups("2041Q2")

    results = requests.map { |group| [group["code"], group["organisationUnits"].map { |ou| ou["id"] }] }.to_h

    expect(results).to eq(
      {
        "GROUP_CSI_1_CODE"      => ["1"],
        "GROUP_CSI_2_CODE"      => ["2"],
        "GROUP_HD_CODE"         => [],
        "GROUP_PROVINCE_CODE"   => [],
        "GROUP_PURCHASE_1_CODE" => [],
        "GROUP_PURCHASE_2_CODE" => [],
        "GROUP_RURAL_CODE"      => ["1"],
        "GROUP_URBAN_CODE"      => ["2"],
        "contracted"            => [],
        "non-contracted"        => %w[1 2 3 X province_id]
      }
    )
  end

  def stub_groups_load
    stub_request(:get, "https://play.dhis2.org/api/organisationUnitGroups?fields=:all&filter=code:eq:GROUP_CSI_1_CODE")
      .to_return(status: 200, body: JSON.pretty_generate(
        {
          organisationUnitGroups: [{
            name:              "CSI I",
            code:              "GROUP_CSI_1_CODE",
            organisationUnits: [{ "id" => "1" }]
          }]
        }
      ))

    stub_request(:get, "https://play.dhis2.org/api/organisationUnitGroups?fields=:all&filter=code:eq:GROUP_CSI_2_CODE")
      .to_return(status: 200, body: JSON.pretty_generate(
        {
          organisationUnitGroups: [{
            name:              "CSI II",
            code:              "GROUP_CSI_2_CODE",
            organisationUnits: [{ "id": "1" }]
          }]
        }
      ))
    stub_request(:get, "https://play.dhis2.org/api/organisationUnitGroups?fields=:all&filter=code:eq:GROUP_HD_CODE")
      .to_return(status: 200, body: JSON.pretty_generate({
                                                           organisationUnitGroups: [{
                                                             name:              "Hospital District",
                                                             code:              "GROUP_HD_CODE",
                                                             organisationUnits: []
                                                           }]
                                                         }))
    stub_request(:get, "https://play.dhis2.org/api/organisationUnitGroups?fields=:all&filter=code:eq:GROUP_PROVINCE_CODE")
      .to_return(status: 200, body: JSON.pretty_generate(
        {
          organisationUnitGroups: [{
            name:              "Hospital District",
            code:              "GROUP_PROVINCE_CODE",
            organisationUnits: [{ "id": "province_id" }, { "id": "1" }]
          }]
        }
      ))

    stub_request(:get, "https://play.dhis2.org/api/organisationUnitGroups?fields=:all&filter=code:eq:GROUP_RURAL_CODE")
      .to_return(status: 200, body: JSON.pretty_generate(
        {
          organisationUnitGroups: [{
            name:              "Rural",
            code:              "GROUP_RURAL_CODE",
            organisationUnits: []
          }]
        }
      ))

    stub_request(:get, "https://play.dhis2.org/api/organisationUnitGroups?fields=:all&filter=code:eq:GROUP_URBAN_CODE")
      .to_return(status: 200, body: JSON.pretty_generate({
                                                           organisationUnitGroups: [{
                                                             name:              "Urban",
                                                             code:              "GROUP_URBAN_CODE",
                                                             organisationUnits: []
                                                           }]
                                                         }))

    stub_request(:get, "https://play.dhis2.org/api/organisationUnitGroups?fields=:all&filter=code:eq:GROUP_PURCHASE_1_CODE")
      .to_return(status: 200, body: JSON.pretty_generate(
        {
          organisationUnitGroups: [{
            name:              "Purchase 1",
            code:              "GROUP_PURCHASE_1_CODE",
            organisationUnits: []
          }]
        }
      ))

    stub_request(:get, "https://play.dhis2.org/api/organisationUnitGroups?fields=:all&filter=code:eq:GROUP_PURCHASE_2_CODE")
      .to_return(status: 200, body: JSON.pretty_generate(
        {
          organisationUnitGroups: [{
            name:              "Purchase 2",
            code:              "GROUP_PURCHASE_2_CODE",
            organisationUnits: []
          }]
        }
      ))

    stub_request(:get, "https://play.dhis2.org/api/organisationUnitGroups?fields=:all&filter=code:eq:contracted")
      .to_return(status: 200, body: JSON.pretty_generate(
        {
          organisationUnitGroups: [{
            name:              "Contracted",
            code:              "contracted",
            organisationUnits: [{ id: "1" }]
          }]
        }
      ))

    stub_request(:get, "https://play.dhis2.org/api/organisationUnitGroups?fields=:all&filter=code:eq:non-contracted")
      .to_return(status: 200, body: JSON.pretty_generate(
        {
          organisationUnitGroups: [{
            name:              "Non-Contracted",
            code:              "non-contracted",
            organisationUnits: [{ id: "1" }]
          }]
        }
      ))
    stub_request(:get, "https://play.dhis2.org/api/organisationUnitGroupSets.json?fields=id,name,code,organisationUnitGroups%5Bid,name,code,organisationUnits~size%5D")
      .to_return(status: 200, body: "", headers: {})
    end
end
