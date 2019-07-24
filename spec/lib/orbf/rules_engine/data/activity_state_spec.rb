RSpec.describe Orbf::RulesEngine::ActivityState do
  it "fails fast with helpful message when formula is missing" do
    expect {
      Orbf::RulesEngine::ActivityState.with(
        kind:    "indicator",
        state:   "mystate",
        ext_id:  "myext_id",
        name:    "myname",
        formula: nil
      )
    }.to raise_error("formula required for indicator : state:'mystate' ext_id:'myext_id' name:'myname' kind:'indicator' formula:'' origin:'dataValueSets'")
  end

  it "fails fast when incorrect kind" do
    expect do
      Orbf::RulesEngine::ActivityState.with(
        kind:    "badbadkind",
        state:   "state",
        ext_id:  "ext_id",
        name:    "name",
        formula: "formula"
      )
    end.to raise_error("Invalid activity state kind 'badbadkind' only supports [\"constant\", \"data_element\", \"indicator\"] : state:'state' ext_id:'ext_id' name:'name' kind:'badbadkind' formula:'formula' origin:'dataValueSets'")
  end
end
