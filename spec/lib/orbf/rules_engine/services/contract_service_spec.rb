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
end
