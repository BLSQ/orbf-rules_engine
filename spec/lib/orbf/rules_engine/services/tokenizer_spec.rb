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
    expect(tokens).to eq(
      [
        "number_of_indicators_reported",
        " ", "", "*", "", " ",
        "Max", "(", "", "%{",
        "actual_health_clynic_type_values",
        "}", "", ")"
      ]
    )
  end

  it "tokenize carriage returns" do
    tokens = described_class.tokenize("(equity_bonus/100) * pma_quantity_total\r\n")
    expect(tokens).to eq ["", "(", "equity_bonus", "/", "100", ")", "", " ", "", "*", "", " ", "pma_quantity_total", "\r\n"]
  end

  it "tokenize carriage returns" do
    tokens = described_class.tokenize("(equity_bonus/100) * pma_quantity_total\n")
    expect(tokens).to eq ["", "(", "equity_bonus", "/", "100", ")", "", " ", "", "*", "", " ", "pma_quantity_total", "\n"]
  end

  it "tokenize equals sign correctly" do
    tokens = described_class.tokenize("if(activity_type=2, \n0,\n1")
    expect(tokens).to eq ["if", "(", "activity_type", "=", "2", ",", "", " ", "", "\n", "0", ",", "", "\n", "1"]
  end

  it "should tokenize non-spaced expressions" do
    tokens = described_class.tokenize("IF(difference_percentage<=5,validated,0)")
    expect(tokens).to eq ["IF", "(", "difference_percentage", "<=", "5", ",", "validated", ",", "0", ")"]
  end

  describe "#format_keys" do
    it "extract format_keys" do
      expect(described_class.format_keys("sample%{vass}")).to eq ["vass"]
      expect(described_class.format_keys("sample%{foo_values} %{bar_values}")).to eq %w[foo_values bar_values]
      expect(described_class.format_keys("sample")).to eq []
    end
  end
end
