
RSpec.describe Orbf::RulesEngine::Package do
  SAME_CODE = "act1_achieved".freeze

  it "validates states and formula codes are not overlapping" do
    expect { build_package }.to raise_error "activity states and activity formulas with same code : [\"act1_achieved\"]"
  end

  def build_package
    Orbf::RulesEngine::Package.new(
      code:       :quantity,
        kind:       :single,
        frequency:  :monthly,
        activities: [
          Orbf::RulesEngine::Activity.with(
            name:            "act1",
            activity_code:   "act1",
            activity_states: [
              Orbf::RulesEngine::ActivityState.new_data_element(
                state:  SAME_CODE,
                ext_id: "dhis2_act1_achieved",
                name:   "act1_achieved"
              )
            ]
          )
        ], rules:      [
          Orbf::RulesEngine::Rule.new(
            kind:     :activity,
            formulas: [
              Orbf::RulesEngine::Formula.new(
                SAME_CODE, "42", ""
              )
            ]
          )
        ]
    )
  end
end
