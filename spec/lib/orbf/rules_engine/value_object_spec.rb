

RSpec.describe Orbf::RulesEngine::ValueObject do
  class SampleValueObject < Orbf::RulesEngine::ValueObject
    attributes :name
  end

  it "verifies all attributes are passed" do
    expect { SampleValueObject.new(id: "") }.to raise_error(
      "SampleValueObject : incorrect number of args no such attributes: extra : [:id] missing: [:name]  possible attributes: [:name]"
    )
  end

  it "help with default to_s" do
    sample = SampleValueObject.new(name:"myname")
    expect(sample.to_s).to match(/#<SampleValueObject:(.*) @name=\"myname\">/)
  end
end
