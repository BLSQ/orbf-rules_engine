RSpec.describe Orbf::RulesEngine::ContractOrgunitsResolver do
  def action(main_orgunit)
    stub_contract_program
    described_class.new(package, pyramid, main_orgunit, contract_service, "2019Q1").call.to_a
  end

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

  let(:matching_groupset_ext_ids) do
    ["GROUPSET_ID_TYPE"]
  end

  let(:package) do
    Orbf::RulesEngine::Package.new(
      code:                        :quantity,
      kind:                        package_kind,
      frequency:                   :monthly,
      activities:                  [],
      rules:                       [],
      main_org_unit_group_ext_ids: %w[GROUP_CSI_1 GROUP_CSI_2],
      groupset_ext_id:             "GROUPSET_ID_TYPE",
      matching_groupset_ext_ids:   matching_groupset_ext_ids
    )
  end

  let(:groupset_type) do
    Orbf::RulesEngine::OrgUnitGroupset.with(
      name:          "groupset",
      ext_id:        "GROUPSET_ID_TYPE",
      group_ext_ids: [group_csi_1, group_csi_2, group_hd, group_province].map(&:ext_id),
      code:          "contracts"
    )
  end

  let(:groupset_locations) do
    Orbf::RulesEngine::OrgUnitGroupset.with(
      name:          "groupset",
      ext_id:        "GROUPSET_ID_LOC",
      group_ext_ids: [group_rural, group_urban].map(&:ext_id),
      code:          "contract_location"
    )
  end

  let(:groupset_purshasing_agency) do
    Orbf::RulesEngine::OrgUnitGroupset.with(
      name:          "groupset",
      ext_id:        "GROUPSET_ID_AG",
      group_ext_ids: [group_purchase_1, group_purchase_2].map(&:ext_id),
      code:          "contract_purshasing_agency"
    )
  end

  let(:orgunit_csi_a) do
    Orbf::RulesEngine::OrgUnit.with(
      ext_id:        "1",
      path:          "country_id/province_id/1",
      name:          "OU1",
      group_ext_ids: []
    )
  end

  let(:orgunit_csi_b) do
    Orbf::RulesEngine::OrgUnit.with(
      ext_id:        "2",
      path:          "country_id/province_id/2",
      name:          "OU2",
      group_ext_ids: []
    )
  end

  let(:orgunit_hd) do
    Orbf::RulesEngine::OrgUnit.with(
      ext_id:        "3",
      path:          "country_id/province_id/3",
      name:          "OU3",
      group_ext_ids: []
    )
  end

  let(:orgunit_not_contracted) do
    Orbf::RulesEngine::OrgUnit.with(
      ext_id:        "4",
      path:          "country_id/province_id/4",
      name:          "OU4",
      group_ext_ids: []
    )
  end

  let(:orgunitx) do
    Orbf::RulesEngine::OrgUnit.with(
      ext_id:        "X",
      path:          "country_id/province_id/X",
      name:          "OUX",
      group_ext_ids: []
    )
  end

  let(:orgunit_province) do
    Orbf::RulesEngine::OrgUnit.with(
      ext_id:        "province_id",
      path:          "country_id/province_id",
      name:          "province",
      group_ext_ids: []
    )
  end

  let(:pyramid) do
    Orbf::RulesEngine::Pyramid.new(
      org_units:          [
        orgunit_csi_a,
        orgunit_csi_b,
        orgunit_hd,
        orgunit_not_contracted,
        orgunitx,
        orgunit_province
      ],
      org_unit_groups:    [
        group_csi_1, group_csi_2, group_hd, group_province,
        group_purchase_1, group_purchase_2,
        group_rural, group_urban
      ],
      org_unit_groupsets: [groupset_type, groupset_locations, groupset_purshasing_agency]
    )
  end

  let(:group_csi_1) do
    Orbf::RulesEngine::OrgUnitGroup.with(
      ext_id: "GROUP_CSI_1",
      name:   "GROUP_CSI_1",
      code:   "GROUP_CSI_1_CODE"
    )
  end

  let(:group_csi_2) do
    Orbf::RulesEngine::OrgUnitGroup.with(
      ext_id: "GROUP_CSI_2",
      name:   "GROUP_CSI_2",
      code:   "GROUP_CSI_2_CODE"
    )
  end

  let(:group_hd) do
    Orbf::RulesEngine::OrgUnitGroup.with(
      ext_id: "GROUP_HD",
      name:   "GROUP_HD",
      code:   "GROUP_HD_CODE"
    )
  end

  let(:group_province) do
    Orbf::RulesEngine::OrgUnitGroup.with(
      ext_id: "GROUP_PROVINCE",
      name:   "GROUP_PROVINCE",
      code:   "GROUP_PROVINCE_CODE"
    )
  end

  let(:group_purchase_1) do
    Orbf::RulesEngine::OrgUnitGroup.with(
      ext_id: "GROUP_PURCHASE_1",
      name:   "GROUP_PURCHASE_1",
      code:   "GROUP_PURCHASE_1_CODE"
    )
  end

  let(:group_purchase_2) do
    Orbf::RulesEngine::OrgUnitGroup.with(
      ext_id: "GROUP_PURCHASE_2",
      name:   "GROUP_PURCHASE_2",
      code:   "GROUP_PURCHASE_2_CODE"
    )
  end

  let(:group_rural) do
    Orbf::RulesEngine::OrgUnitGroup.with(
      ext_id: "GROUP_RURAL",
      name:   "GROUP_RURAL",
      code:   "GROUP_RURAL_CODE"
    )
  end

  let(:group_urban) do
    Orbf::RulesEngine::OrgUnitGroup.with(
      ext_id: "GROUP_URBAN",
      name:   "GROUP_URBAN",
      code:   "GROUP_URBAN_CODE"
    )
  end

  context "single package" do
    let(:package_kind) { :single }

    context "simple package for CSI I or II" do
      let(:package) do
        Orbf::RulesEngine::Package.new(
          code:                        :quantity,
          kind:                        package_kind,
          frequency:                   :monthly,
          activities:                  [],
          rules:                       [],
          main_org_unit_group_ext_ids: [group_csi_1, group_csi_2].map(&:ext_id),
          groupset_ext_id:             nil,
          matching_groupset_ext_ids:   []
        )
      end

      it "return [] if no contracts" do
        expect(action(orgunit_not_contracted)).to eq []
      end

      it "returns only matching" do
        expect(action(orgunit_csi_a)).to eq [orgunit_csi_a]
        expect(action(orgunit_csi_b)).to eq [orgunit_csi_b]
      end

      it "returns empty array if doesnt belong to package's org_unit_group_ext_ids" do
        expect(action(orgunit_hd)).to eq([])
      end
    end

    context "simple package for CSI I or II specifying a matching_groupset_ext_id" do
      let(:package) do
        Orbf::RulesEngine::Package.new(
          code:                        :quantity,
          kind:                        package_kind,
          frequency:                   :monthly,
          activities:                  [],
          rules:                       [],
          main_org_unit_group_ext_ids: [group_csi_1, group_csi_2].map(&:ext_id),
          groupset_ext_id:             nil,
          matching_groupset_ext_ids:   ["GROUPSET_ID_TYPE"]
        )
      end

      it "return [] if no contracts" do
        expect(action(orgunit_not_contracted)).to eq []
      end

      it "returns only matching" do
        expect(action(orgunit_csi_a)).to eq [orgunit_csi_a]
        expect(action(orgunit_csi_b)).to eq [orgunit_csi_b]
      end

      it "returns empty array if doesnt belong to package's org_unit_group_ext_ids" do
        expect(action(orgunit_hd)).to eq([])
      end
    end

    context "simple package for CSI I or II but only rural" do
      let(:package) do
        Orbf::RulesEngine::Package.new(
          code:                        :quantity,
          kind:                        package_kind,
          frequency:                   :monthly,
          activities:                  [],
          rules:                       [],
          main_org_unit_group_ext_ids: [group_csi_1, group_csi_2, group_rural].map(&:ext_id),
          groupset_ext_id:             nil,
          matching_groupset_ext_ids:   [groupset_type, groupset_locations].map(&:ext_id)
        )
      end
      it "return [] if no contracts" do
        expect(action(orgunit_not_contracted)).to eq []
      end

      it "returns only matching" do
        expect(action(orgunit_csi_a)).to eq [orgunit_csi_a]
      end

      it "returns empty array if doesnt belong to package's org_unit_group_ext_ids" do
        expect(action(orgunit_hd)).to eq([])
        expect(action(orgunit_csi_b)).to eq([])
      end
    end
  end

  context "subcontract package" do
    let(:package_kind) { :subcontract }
    let(:package) do
      Orbf::RulesEngine::Package.new(
        code:                        :quantity,
        kind:                        package_kind,
        frequency:                   :monthly,
        activities:                  [],
        rules:                       [],
        main_org_unit_group_ext_ids: [group_province].map(&:ext_id),
        groupset_ext_id:             groupset_type.ext_id
      )
    end
    it "return [] if no contracts" do
      expect(action(orgunit_not_contracted)).to eq []
    end
    it "return main and contracted" do
      expect(action(orgunit_province)).to eq [orgunit_province, orgunitx]
    end
  end

  context "zone package all under matching target groups" do
    let(:package_kind) { :zone }
    let(:package) do
      Orbf::RulesEngine::Package.new(
        code:                          :quantity,
        kind:                          package_kind,
        frequency:                     :monthly,
        activities:                    [],
        rules:                         [],
        main_org_unit_group_ext_ids:   [group_province].map(&:ext_id),
        target_org_unit_group_ext_ids: [group_csi_1, group_csi_2, group_hd].map(&:ext_id),
        groupset_ext_id:               groupset_type.ext_id
      )
    end

    it "return [] if no contracts" do
      expect(action(orgunit_not_contracted)).to eq []
    end

    it "return [] if not main groups" do
      expect(action(orgunit_csi_a)).to eq []
    end

    it "return main and all descendants matching the target groups" do
      expect(action(orgunit_province)).to eq [orgunit_province, orgunit_csi_a, orgunit_csi_b]
    end
  end

  context "zone package à la subcontract (liberia)" do
    let(:package_kind) { :zone }
    let(:package) do
      Orbf::RulesEngine::Package.new(
        code:                          :quantity,
        kind:                          package_kind,
        frequency:                     :monthly,
        activities:                    [],
        rules:                         [],
        main_org_unit_group_ext_ids:   [group_province].map(&:ext_id),
        target_org_unit_group_ext_ids: [],
        groupset_ext_id:               groupset_type.ext_id
      )
    end

    it "returns main and target based on contract group" do
      expect(action(orgunit_province)).to eq [orgunit_province, orgunitx]
    end
  end

end
