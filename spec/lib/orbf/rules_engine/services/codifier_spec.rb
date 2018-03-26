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
end