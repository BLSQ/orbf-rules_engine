
RSpec.describe Orbf::RulesEngine::ValueFormatter do
  it "keeps decimals as they are" do
    expect(described_class.format(1.0001)).to eq(1.0001)
  end
  it "keeps string decimals as decimals" do
    expect(described_class.format("1.0001")).to eq(1.0001)
  end
  it "transforms floats into integers" do
    expect(described_class.format(1.0)).to eq(1)
  end
  it "transforms float into integer equivalents" do
    expect(described_class.format("1.0")).to eq(1)
    expect(described_class.format("1.0").to_s).to eq("1")
  end
  it "keeps integer as they are" do
    expect(described_class.format(1)).to eq(1)
  end
  it "keeps string integer as integers" do
    expect(described_class.format("1")).to eq(1)
    expect(described_class.format("1").to_s).to eq("1")
  end
end
