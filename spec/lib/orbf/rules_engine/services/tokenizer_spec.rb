RSpec.describe Orbf::RulesEngine::Tokenizer do
  it "should tokenize" do
    expression = "SUM(%{actual_weight_values})"
    tokens = described_class.tokenize(expression)
    expect(tokens.join("")).to eq(expression)
    expect(tokens).to eq(["SUM", "(", "", "%{", "actual_weight_values", "}", "", ")"])
  end

  it "should tokenize 2 " do
    expression = "number_of_indicators_reported * Max(%{actual_health_clynic_type_values})"
    tokens = described_class.tokenize(expression)
    expect(tokens.join("")).to eq(expression)
    expect(tokens).to eq([
      "number_of_indicators_reported", 
      " ", "", "*", "", " ",
       "Max", "(", "", "%{",
        "actual_health_clynic_type_values", 
        "}", "", ")"
      ])
  end

  describe "#format_keys" do
    it "extract format_keys" do
      expect(described_class.format_keys("sample%{vass}")).to eq ["vass"]
      expect(described_class.format_keys("sample%{foo_values} %{bar_values}")).to eq %w[foo_values bar_values]
      expect(described_class.format_keys("sample")).to eq []
    end
  end
end
