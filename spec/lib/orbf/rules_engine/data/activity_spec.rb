RSpec.describe Orbf::RulesEngine::Activity do
  it "fails fast when incorrect kind" do
    expect do
      Orbf::RulesEngine::ActivityState.with(
        kind:    "badbadkind",
        state:   "state",
        ext_id:  "ext_id",
        name:    "name",
        formula: "formula"
      )
    end.to raise_error('Kind badbadkind must be one of ["constant", "data_element", "indicator"]')
  end
end
