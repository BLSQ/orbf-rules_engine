RSpec.describe "Sigl System" do
  let(:raw_activities) { JSON.parse(fixture_content(:rules_engine, "sigl.json")) }

  let(:raw_cocs) { JSON.parse(fixture_content(:rules_engine, "sigl-coc.json")).index_by { |a| a["id"] } }

  let(:states) do
    raw_cocs["EXosnAykaQv"]["categoryOptionCombos"].map do |coc|
      { coc_reference: coc["id"], code: Orbf::RulesEngine::Codifier.codify(coc["name"]), name: coc["name"] }
    end
  end

  let(:activities) do
    raw_activities.map do |raw_activity|
      name = (raw_activity[1] + " " + raw_activity[2]).gsub("\n"," ").squeeze(' ')
      code = "mal" + raw_activity[0]
      Orbf::RulesEngine::Activity.with(
        activity_code:   code,
        name:            name,
        activity_states: states.map do |state|
                           raw_activity_state = raw_activity.find { |a| a && a["input"] && a["input"]["id"] && a["input"]["id"].include?(state[:coc_reference]) }
                           next unless raw_activity_state
                           composites = raw_activity_state["input"]["id"].split("-")
                           activity_state_name =  (name + " - " + state[:name]).gsub("\n"," ").squeeze(' ')
                           Orbf::RulesEngine::ActivityState.new_indicator(
                             state:   state[:code],
                             ext_id:  "dhis2_#{code}_#{state[:code]}_indicator",
                             expression: "\#{"+composites[0..1].join(".")+"}",
                             name: activity_state_name
                           )
                         end.compact
      )
    end
  end

  let(:project) do
    Orbf::RulesEngine::Project.new(
      packages: [
        Orbf::RulesEngine::Package.new(
          code:       :facility,
          kind:       :zone,
          frequency:  :monthly,
          activities: activities,
          target_org_unit_group_ext_ids: ["dhis_facilities"],
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
    project
    puts YAML.dump(project, BestWidth: 500, :use_version => true)
  end
end
