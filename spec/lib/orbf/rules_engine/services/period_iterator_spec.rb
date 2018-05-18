
RSpec.describe Orbf::RulesEngine::PeriodIterator do
  it "converts year to various periodicity" do
    expect(described_class.periods("2018", "monthly")).to eq(
      %w[201801 201802 201803 201804 201805 201806 201807 201808 201809 201810 201811 201812]
    )
    expect(described_class.periods("2018", "quarterly")).to eq(
      %w[2018Q1 2018Q2 2018Q3 2018Q4]
    )
    expect(described_class.periods("2018", "yearly")).to eq(
      ["2018"]
    )
  end

  it "converts quarter to various periodicity" do
    expect(described_class.periods("2018Q3", "monthly")).to eq(
      %w[201807 201808 201809]
    )
    expect(described_class.periods("2018Q3", "quarterly")).to eq(
      %w[2018Q3]
    )
    expect(described_class.periods("2018Q3", "yearly")).to eq(
      ["2018"]
    )
    expect(described_class.periods("2018Q3", "yearly")).to eq(
      ["2018"]
    )
  end

  context "financial year" do
    it "converts year to financial_july" do
      expect(described_class.periods("2018", "financial_july")).to eq(
        %w[2017July 2018July]
      )
    end

    it "converts quarter to financial_july" do
      expect(described_class.periods("2018Q3", "financial_july")).to eq(
        ["2018July"]
      )

      expect(described_class.periods("2018Q1", "financial_july")).to eq(
        ["2017July"]
      )
    end

    it "converts month to financial_july" do
      expect(described_class.periods("201803", "financial_july")).to eq(
        ["2017July"]
      )

      expect(described_class.periods("201808", "financial_july")).to eq(
        ["2018July"]
      )
    end
  end
end
