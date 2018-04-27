

RSpec.describe Orbf::RulesEngine::FetchAndSolve do
  include Dhis2Stubs

  let(:activities) do
    [
      Orbf::RulesEngine::Activity.with(
        name:            "act1",
        activity_code:   "act1",
        activity_states: [
          Orbf::RulesEngine::ActivityState.new_data_element(
            state:  :active,
            name:   "act1_active",
            ext_id: "dhis2activedataelementid"
          )
        ]
      )
    ]
  end

  describe "with matching package group" do
    let(:project) { build_project(package) }
    let(:package) { build_package("f25dqv3Y7Z0") }

    it "fetch pyramid and dhis2 values" do
      stub_orgunits
      stub_orgunit_groups
      stub_orgunit_groupsets

      stub_request(:get, "https://play.dhis2.org/2.28/api/dataValueSets?children=false&dataSet=data_set_id&orgUnit=ImspTQPwCqd&orgUnit=Rp268JB6Ne4&orgUnit=at6UHUQatSo&orgUnit=qtr8GGlm4gg&period=2016&period=2016Q1")
        .to_return(status: 200, body: {}.to_json)

      fetch_and_solve = described_class.new(project, "Rp268JB6Ne4", "2016Q1")
      fetch_and_solve.call

      expect(fetch_and_solve.solver).to be_a(Orbf::RulesEngine::Solver)
      expect(fetch_and_solve.exported_values).to eq(
        [
          { dataElement: "achieved_dhis2id",
            orgUnit:     "Rp268JB6Ne4",
            period:      "2016Q1",
            value:       0,
            comment:     "facility_act1_achieved_for_Rp268JB6Ne4_and_2016q1" }
        ]
      )
      expect(fetch_and_solve.dhis2_values).to eq([])
      expect(fetch_and_solve.pyramid).to be_a(Orbf::RulesEngine::Pyramid)
    end

    it "allow to pass mocked dhis2 values" do
      stub_orgunits
      stub_orgunit_groups
      stub_orgunit_groupsets

      fetch_and_solve = described_class.new(project, "Rp268JB6Ne4", "2016Q1", mock_values: [])
      fetch_and_solve.call

      expect(fetch_and_solve.solver).to be_a(Orbf::RulesEngine::Solver)
      expect(fetch_and_solve.exported_values).to eq(
        [
          { dataElement: "achieved_dhis2id",
            orgUnit:     "Rp268JB6Ne4",
            period:      "2016Q1",
            value:       0,
            comment:     "facility_act1_achieved_for_Rp268JB6Ne4_and_2016q1" }
        ]
      )
      expect(fetch_and_solve.dhis2_values).to eq([])
      expect(fetch_and_solve.pyramid).to be_a(Orbf::RulesEngine::Pyramid)
    end

    it "allow to pass mocked pyramid" do
      pyramid = Orbf::RulesEngine::Pyramid.new(
        org_units: [
          OpenStruct.new(ext_id: "Rp268JB6Ne4", group_ext_ids: [])
        ], org_unit_groups: [], org_unit_groupsets: []
      )

      fetch_and_solve = described_class.new(project, "Rp268JB6Ne4", "2016Q1", mock_values: [], pyramid: pyramid)
      fetch_and_solve.call

      expect(fetch_and_solve.solver).to be_a(Orbf::RulesEngine::Solver)
      expect(fetch_and_solve.exported_values).to eq([])
      expect(fetch_and_solve.dhis2_values).to eq([])
      expect(fetch_and_solve.pyramid).to eq(pyramid)
    end
  end

  describe "without matching package group" do
    let(:project) { build_project(package) }
    let(:package) { build_package("nlX2VoouN63") }

    it "fetch pyramid and no dhis2 values" do
      stub_orgunits
      stub_orgunit_groups
      stub_orgunit_groupsets

      fetch_and_solve = described_class.new(project, "Rp268JB6Ne4", "2016Q1")
      fetch_and_solve.call
      expect(fetch_and_solve.solver).to be_a(Orbf::RulesEngine::Solver)
      expect(fetch_and_solve.exported_values).to eq([])
      expect(fetch_and_solve.dhis2_values).to eq([])
      expect(fetch_and_solve.pyramid).to be_a(Orbf::RulesEngine::Pyramid)
    end
  end

  def build_project(package)
    Orbf::RulesEngine::Project.new(
      packages:     [package],
      dhis2_params: {
        url:      "https://admin:district@play.dhis2.org/2.28",
        user:     "admin",
        password: "district"
      }
    )
  end

  def build_package(group)
    Orbf::RulesEngine::Package.new(
      code:                   :facility,
      kind:                   :single,
      frequency:              :quarterly,
      activities:             activities,
      dataset_ext_ids:        ["data_set_id"],
      org_unit_group_ext_ids: [group],
      rules:                  [
        Orbf::RulesEngine::Rule.new(
          kind:     :activity,
          formulas: [
            Orbf::RulesEngine::Formula.new(
              "achieved", "15 * active",
              activity_mappings: { "act1" => "achieved_dhis2id" }
            )
          ]
        )
      ]
    )
  end
end
