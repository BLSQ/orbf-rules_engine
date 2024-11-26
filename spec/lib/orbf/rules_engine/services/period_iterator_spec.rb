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

  context "quarterlyNov" do
    it "converts quarterNov to monthly with offset" do
      expect(described_class.periods("2016NovQ1", "monthly")).to eq(
        %w[201511 201512 201601]
      )
      expect(described_class.periods("2016NovQ2", "monthly")).to eq(
        %w[201602 201603 201604]
      )
      expect(described_class.periods("2016NovQ3", "monthly")).to eq(
        %w[201605 201606 201607]
      )
      expect(described_class.periods("2016NovQ4", "monthly")).to eq(
        %w[201608 201609 201610]
      )
    end

    it "converts quarter to various periodicity" do
      expect(described_class.periods("2016NovQ1", "quarterly")).to eq(
        %w[2015Q4 2016Q1]
      )
      expect(described_class.periods("2016NovQ1", "yearly")).to eq(
        %w[2015 2016]
      )
      expect(described_class.periods("2016NovQ2", "yearly")).to eq(
        ["2016"]
      )
      expect(described_class.periods("2016NovQ1", "financial_nov")).to eq(
        ["2016Nov"]
      )
    end

    it "converts quarterly_nov to quarterly_nov" do
      expect(described_class.periods("2016NovQ1", "quarterly_nov")).to eq(["2016NovQ1"])
      expect(described_class.periods("2016NovQ2", "quarterly_nov")).to eq(["2016NovQ2"])
      expect(described_class.periods("2016NovQ3", "quarterly_nov")).to eq(["2016NovQ3"])
      expect(described_class.periods("2016NovQ4", "quarterly_nov")).to eq(["2016NovQ4"])
    end

    it "converts yearly_nov to quarterly_nov" do
      expect(described_class.periods("2016Nov", "quarterly_nov")).to eq(
        %w[2016NovQ1 2016NovQ2 2016NovQ3 2016NovQ4]
      )
    end

    it "converts yearly to quarterlyNov" do
      expect(described_class.periods("2016", "quarterly_nov")).to eq(
        %w[2017NovQ1]
      )
      # TODO don't
    end
  end

  context "financial july year" do
    it "converts financial_july to month" do
      expect(described_class.periods("2018July", "monthly")).to eq(
        %w[201807 201808 201809 201810 201811 201812 201901 201902 201903 201904 201905 201906]
      )
    end
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
      expect(described_class.periods("201806", "financial_july")).to eq(
        ["2017July"]
      )
      expect(described_class.periods("201807", "financial_july")).to eq(
        ["2018July"]
      )
      expect(described_class.periods("201808", "financial_july")).to eq(
        ["2018July"]
      )
    end
  end

  context "financial nov year" do
    it "converts financial nov to month" do
      expect(described_class.periods("2018Nov", "monthly")).to eq(
        %w[201711 201712 201801 201802 201803 201804 201805 201806 201807 201808 201809 201810]
      )
    end

    it "converts year to financial_nov" do
      expect(described_class.periods("2016", "financial_nov")).to eq(
        %w[2016Nov]
      )
      # TODO don't know why I would have expected 2016Nov and 2017Nov
    end

    it "converts quarter to financial_nov" do
      expect(described_class.periods("2016Q4", "financial_nov")).to eq(
        ["2016Nov"]
      )

      expect(described_class.periods("2016Q3", "financial_nov")).to eq(
        ["2016Nov"]
      )

      expect(described_class.periods("2016Q2", "financial_nov")).to eq(
        ["2016Nov"]
      )

      expect(described_class.periods("2016Q1", "financial_nov")).to eq(
        ["2016Nov"]
      )
    end

    it "converts quarter_nov to financial_nov" do
      expect(described_class.periods("2018NovQ3", "financial_nov")).to eq(
        ["2018Nov"]
      )

      expect(described_class.periods("2018NovQ1", "financial_nov")).to eq(
        ["2018Nov"]
      )

      expect(described_class.periods("2017NovQ1", "financial_nov")).to eq(
        ["2017Nov"]
      )
    end

    it "converts month to financial_nov" do
      expect(described_class.periods("201603", "financial_nov")).to eq(
        ["2016Nov"]
      )
      expect(described_class.periods("201606", "financial_nov")).to eq(
        ["2016Nov"]
      )
      expect(described_class.periods("201607", "financial_nov")).to eq(
        ["2016Nov"]
      )
      expect(described_class.periods("201608", "financial_nov")).to eq(
        ["2016Nov"]
      )
      expect(described_class.periods("201609", "financial_nov")).to eq(
        ["2016Nov"]
      )
      expect(described_class.periods("201610", "financial_nov")).to eq(
        ["2016Nov"]
      )
      expect(described_class.periods("201611", "financial_nov")).to eq(
        ["2017Nov"]
      )

      expect(described_class.periods("201612", "financial_nov")).to eq(
        ["2017Nov"]
      )
      expect(described_class.periods("201701", "financial_nov")).to eq(
        ["2017Nov"]
      )
      expect(described_class.periods("201702", "financial_nov")).to eq(
        ["2017Nov"]
      )
    end
  end
end
