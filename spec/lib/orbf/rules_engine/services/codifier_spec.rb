RSpec.describe Orbf::RulesEngine::Codifier do
  let(:subject) { described_class }

  it "lower case and unaccent stuff" do
    expect(subject.codify("Privé")).to eq("prive")
  end

  it "replace spaces are replaced and duplicated one are compressed" do
    expect(subject.codify("Hospital   Privé")).to eq("hospital_prive")
  end

  it "replace - are replaced" do
    expect(subject.codify("Hospital-Privé")).to eq("hospital_prive")
  end

  it "replace - are replaced" do
    expect(subject.codify("pma/Pca")).to eq("pma_pca")
  end

  it "replace double spaces" do
    expect(subject.codify("pma  Pca")).to eq("pma_pca")
  end

  it "replace double spaces" do
    expect(subject.codify("pma - Pca")).to eq("pma__pca")
  end

  it "doesn't touch codified code" do
    expect(subject.codify("pma__pca")).to eq("pma__pca")
  end

  it "nil safe" do
    expect(subject.codify(nil)).to eq(nil)
  end
end