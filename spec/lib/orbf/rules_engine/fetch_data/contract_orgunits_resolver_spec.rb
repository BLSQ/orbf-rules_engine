RSpec.describe Orbf::RulesEngine::ContractOrgunitsResolver do
  def action(main_orgunit)
    stub_contract_program
    described_class.new(package, pyramid, main_orgunit, contract_service, "2019Q1").call.to_a
  end

  def stub_contract_program
    stub_request(:get, "https://play.dhis2.org/api/sqlViews/DHIS2ALLEVENTSQLVIEWID/data.json?paging=false&var=programId:DHIS2CONTRACTPROGRAMID")
      .to_return(status: 200, body: fixture_content(:dhis2, "contract_raw_events.json"))
    stub_request(:get, "https://play.dhis2.org/api/programs/DHIS2CONTRACTPROGRAMID?fields=id,name,programStages%5BprogramStageDataElements%5BdataElement%5Bid,name,code,optionSet%5Bid,name,code,options%5Bid,name%5D%5D%5D%5D&paging=false")
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

  let(:matching_groupset_ext_ids) do
    []
  end

  let(:package) do
    Orbf::RulesEngine::Package.new(
      code:                        :quantity,
      kind:                        package_kind,
      frequency:                   :monthly,
      activities:                  [],
      rules:                       [],
      main_org_unit_group_ext_ids: ["GROUP_X"],
      groupset_ext_id:             "GROUPSET_ID",
      matching_groupset_ext_ids:   matching_groupset_ext_ids
    )
  end

  let(:groupset) do
    Orbf::RulesEngine::OrgUnitGroupset.with(
      name:          "groupset",
      ext_id:        "GROUPSET_ID",
      group_ext_ids: %w[GROUP_1 GROUP_2],
      code:          "contracts"
    )
  end

  let(:orgunit1) do
    Orbf::RulesEngine::OrgUnit.with(
      ext_id:        "1",
      path:          "country_id/county_id/1",
      name:          "OU1",
      group_ext_ids:  [] #["GROUP_1"] but now based on contract
    )
  end

  let(:orgunit2) do
    Orbf::RulesEngine::OrgUnit.with(
      ext_id:        "2",
      path:          "country_id/county_id/2",
      name:          "OU2",
      group_ext_ids:  [] #["GROUP_2"] but now based on contract
    )
  end

  let(:orgunit3) do
    Orbf::RulesEngine::OrgUnit.with(
      ext_id:        "3",
      path:          "country_id/county_id/3",
      name:          "OU3",
      group_ext_ids: [] #["GROUP_3"] but now based on contract
    )
  end

  let(:orgunit4) do
    Orbf::RulesEngine::OrgUnit.with(
      ext_id:        "4",
      path:          "country_id/county_id/4",
      name:          "OU4",
      group_ext_ids:  [] #%w[GROUP_X GROUP_1] but now based on contract
    )
  end

  let(:orgunitx) do
    Orbf::RulesEngine::OrgUnit.with(
      ext_id:        "X",
      path:          "country_id/county_id/X",
      name:          "OUX",
      group_ext_ids:  [] #["GROUP_X"] but now based on contract
    )
  end

  let(:pyramid) do
    Orbf::RulesEngine::Pyramid.new(
      org_units:          [orgunit1, orgunit2, orgunit3, orgunit4, orgunitx],
      org_unit_groups:    [groupx, group1, group2, group3],
      org_unit_groupsets: [groupset]
    )
  end

  let(:groupx) do
    Orbf::RulesEngine::OrgUnitGroup.with(
      ext_id: "GROUP_X",
      name:   "GROUP X",
      code:   "GROUP_X_CODE"
    )
  end

  let(:group1) do
    Orbf::RulesEngine::OrgUnitGroup.with(
      ext_id: "GROUP_1",
      name:   "GROUP 1",
      code:   "GROUP_1_CODE"
    )
  end

  let(:group2) do
    Orbf::RulesEngine::OrgUnitGroup.with(
      ext_id: "GROUP_2",
      name:   "GROUP 2",
      code:   "GROUP_2_CODE"
    )
  end

  let(:group3) do
    Orbf::RulesEngine::OrgUnitGroup.with(
      ext_id: "GROUP_3",
      name:   "GROUP 3",
      code:   "GROUP_3_CODE"
    )
  end

  context "subcontract package" do
    let(:package_kind) { :subcontract }

    it "doesnt return anything if main orgunit not in package's org_unit_group_ext_ids" do
      expect(action(orgunit3)).to eq []
    end

    it "returns main org unit + ous in intersection of its group_ext_ids and the one in the groupset" do
      expect(action(orgunitx)).to eq [orgunitx]
      expect(action(orgunit4)).to eq [orgunit4, orgunit1]
    end
  end

  context "single package" do
    let(:package_kind) { :single }

    it "only matching" do
      expect(action(orgunit4)).to eq [orgunit4]
      expect(action(orgunitx)).to eq [orgunitx]
    end

    it "returns empty array if doesnt belong to package's org_unit_group_ext_ids" do
      expect(action(orgunit3)).to eq []
    end
  end

  context "single package and matching groupset" do
    describe "when correct groupset" do
      let(:package_kind) { :single }
      let(:matching_groupset_ext_ids) { "GROUPSET_ID" }

      it "only matching" do
        expect(action(orgunit4)).to eq [orgunit4]
        expect(action(orgunitx)).to eq [orgunitx]
      end

      it "returns empty array if doesnt belong to package's org_unit_group_ext_ids" do
        expect(action(orgunit3)).to eq []
      end
    end

    describe "when other groupset" do
      let(:package_kind) { :single }
      let(:matching_groupset_ext_ids) { "GROUPSET_other_ID" }

      it "only matching" do
        expect(action(orgunit4)).to eq [orgunit4]
        expect(action(orgunitx)).to eq [orgunitx]
      end

      it "returns empty array if doesnt belong to package's org_unit_group_ext_ids" do
        expect(action(orgunit3)).to eq []
      end
    end
  end

  context "zone/liberia type" do
    let(:package_kind) { :zone }

    it "doesnt return anything if main orgunit not in package's org_unit_group_ext_ids" do
      expect(action(orgunit3)).to eq []
    end

    it "returns main org unit + ous in intersection of its group_ext_ids and the one in the groupset" do
      expect(action(orgunitx)).to eq [orgunitx]
      expect(action(orgunit4)).to eq [orgunit4, orgunit1]
    end
  end

  context "zone/burundi type" do
    let(:package_kind) { :zone }

    let(:package) do
      Orbf::RulesEngine::Package.new(
        code:                        :quantity,
        kind:                        package_kind,
        frequency:                   :monthly,
        activities:                  [],
        rules:                       [],
        main_org_unit_group_ext_ids: ["GROUP_X"],
        groupset_ext_id:             "GROUPSET_ID",
        matching_groupset_ext_ids:   matching_groupset_ext_ids,
        include_main_orgunit:        true
      )
    end

    it "doesnt return anything if main orgunit not in package's org_unit_group_ext_ids" do
      expect(action(orgunit3)).to eq []
    end

    it "returns main org unit + ous in intersection of its group_ext_ids and the one in the groupset" do
      expect(action(orgunitx)).to eq [orgunitx, orgunitx]
    end

    it "returns main org unit + ous in intersection of its group_ext_ids and the one in the groupset" do
      expect(action(orgunit4)).to eq [orgunit4, orgunit1, orgunit4]
    end
  end
end
