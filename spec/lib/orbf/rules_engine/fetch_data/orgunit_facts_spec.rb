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

  describe "with group based" do
    let(:subject) { described_class.new(org_unit: org_unit, pyramid: pyramid, contract_service: nil, invoicing_period: nil) }

    it "calculates all facts" do
      expect(subject.to_facts).to eq(
        "groupset_code_types" => "pma",
        "level"               => "3",
        "level_1"             => "country_id",
        "level_2"             => "county_id",
        "level_3"             => "1",
        "groupset_origin" => "groups",
      )
    end
  end

  describe "with contract based" do
    def stub_contract_program
      stub_request(:get, "https://play.dhis2.org/api/sqlViews/DHIS2ALLEVENTSQLVIEWID/data.json?paging=false&var=programId:DHIS2CONTRACTPROGRAMID")
        .to_return(status: 200, body: fixture_content(:dhis2, "contract_raw_events.json"))
      stub_request(:get, "https://play.dhis2.org/api/programs/DHIS2CONTRACTPROGRAMID?fields=id,name,programStages%5BprogramStageDataElements%5BdataElement%5Bid,name,code,optionSet%5Bid,name,code,options%5Bid,code,name%5D%5D%5D%5D&paging=false")
        .to_return(status: 200, body: fixture_content(:dhis2, "contract_program.json"))
    end

    let(:dhis2_params) do
      {
        url:      "https://play.dhis2.org",
        user:     "admin",
        password: "district"
      }
    end

    let(:contract_service) do
      Orbf::RulesEngine::ContractService.new(
        program_id:            "DHIS2CONTRACTPROGRAMID",
        all_event_sql_view_id: "DHIS2ALLEVENTSQLVIEWID",
        dhis2_connection:      Dhis2::Client.new(dhis2_params),
        calendar:              ::Orbf::RulesEngine::GregorianCalendar.new
      )
    end

    it "calculates facts based on contracts even when no contract" do
      stub_contract_program
      subject = described_class.new(org_unit: org_unit, pyramid: pyramid, contract_service: contract_service, invoicing_period: "2010Q1")

      expect(subject.to_facts).to eq({
                                       "level"   => "3",
                                       "level_1" => "country_id",
                                       "level_2" => "county_id",
                                       "level_3" => "1"
                                     })
    end

    it "calculates facts based on contracts even when contract" do
      stub_contract_program
      subject = described_class.new(org_unit: org_unit, pyramid: pyramid, contract_service: contract_service, invoicing_period: "2018Q3")

      expect(subject.to_facts).to eq({
                                       "groupset_code_contract_location" => "group_rural_code",
                                       "groupset_code_contract_type"     => "group_csi_1_code",
                                       "level"                           => "3",
                                       "level_1"                         => "country_id",
                                       "level_2"                         => "county_id",
                                       "level_3"                         => "1",
                                       "groupset_origin"                 => "contracts"
                                     })
    end
  end
end
