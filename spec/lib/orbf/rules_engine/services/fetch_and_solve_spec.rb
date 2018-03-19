

RSpec.describe Orbf::RulesEngine::FetchAndSolve do
  include Dhis2Stubs

  let(:project) do
    Orbf::RulesEngine::Project.new(
      packages:     [package],
      dhis2_params: {
        url:     "https://admin:district@play.dhis2.org/2.28",
        version: "2.28"
      }
    )
  end

  let(:package) do
    Orbf::RulesEngine::Package.new(
      code:       :facility,
      kind:       :single,
      frequency:  :quarterly,
      activities: activities,
      rules:      []
    )
  end

  let(:activities) do
    [
      Orbf::RulesEngine::Activity.with(
        name:            "act1",
        activity_code:   "act1",
        activity_states: [
          Orbf::RulesEngine::ActivityState.new_constant(
            state:   :active,
            name:    "act1_active",
            formula: "10"
          )
        ]
      )
    ]
  end

  it "fetch pyramid and dhis2 values" do
    stub_orgunits
    stub_orgunit_groups
    stub_orgunit_groupsets

    stub_values(
      dataValues: []
    )
    Orbf::RulesEngine::FetchAndSolve.new(project, "Rp268JB6Ne4", "2016Q1").call
  end
end
