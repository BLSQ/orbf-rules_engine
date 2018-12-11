RSpec.describe "Sigl System" do
  let(:raw_activities) { JSON.parse(fixture_content(:rules_engine, "sigl.json")) }

  let(:raw_cocs) { JSON.parse(fixture_content(:rules_engine, "sigl-coc.json")).index_by { |a| a["id"] } }

  let(:states) do
    raw_cocs["EXosnAykaQv"]["categoryOptionCombos"].map do |coc|

      { coc_reference: coc["id"], code: Orbf::RulesEngine::Codifier.codify(coc["name"]), name: coc["name"] }
    end
  end

  let(:activities) do
    raw_activities.map do |activity|
      Orbf::RulesEngine::Activity.with(
        name:            "mal" + activity[0],
        activity_code:   activity[1] + " " + activity[2],
        activity_states: states.map do |_state|
                           byebug
                         end
      )
    end
  end

  let(:project) do
    Orbf::RulesEngine::Project.new(
      packages: [
        Orbf::RulesEngine::Package.new(
          code:       :facility,
          kind:       :zone,
          frequency:  :quarterly,
          activities: activities,
          rules:      [
            Orbf::RulesEngine::Rule.new(
              kind:     :activity,
              formulas: [
              ]
            )
          ]
        )
      ]
    )
  end

  it "works" do
    activities
  end
end
