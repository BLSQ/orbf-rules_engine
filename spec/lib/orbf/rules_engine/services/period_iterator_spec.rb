
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
      expect(described_class.periods("2018NovQ1", "monthly")).to eq(
        %w[201811 201812 201901]
      )
      expect(described_class.periods("2018NovQ2", "monthly")).to eq(
        %w[201902 201903 201904]
      )
      expect(described_class.periods("2018NovQ3", "monthly")).to eq(
        %w[201905 201906 201907]
      )
      expect(described_class.periods("2018NovQ4", "monthly")).to eq(
        %w[201908 201909 201910]
      )
    end

    it "converts quarter to various periodicity" do
      expect(described_class.periods("2018NovQ1", "quarterly")).to eq(
        ["2018Q4", "2019Q1"]
      )
      expect(described_class.periods("2018NovQ1", "yearly")).to eq(
        ["2018","2019"]
      )
      expect(described_class.periods("2018NovQ2", "yearly")).to eq(
        ["2019"]
      )
      expect(described_class.periods("2018NovQ1", "financial_nov")).to eq(
        ["2018Nov"]
      )
    end  
  end

  context "financial july year" do
    it "converts financial_july to month" do 
      expect(described_class.periods("2018July", "monthly")).to eq(
        ["201807", "201808", "201809", "201810", "201811", "201812", "201901", "201902", "201903", "201904", "201905", "201906"]
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
        ["201811", "201812", "201901", "201902", "201903", "201904", "201905", "201906", "201907", "201908", "201909", "201910"]
      )
    end


    it "converts year to financial_nov" do
      expect(described_class.periods("2018", "financial_nov")).to eq(
        %w[2017Nov 2018Nov]
      )
    end

    it "converts quarter to financial_nov" do
      expect(described_class.periods("2018Q4", "financial_nov")).to eq(
        ["2018Nov"]
      )

      expect(described_class.periods("2018Q3", "financial_nov")).to eq(
        ["2017Nov"]
      )

      expect(described_class.periods("2018Q4", "financial_nov")).to eq(
        ["2018Nov"]
      )

      expect(described_class.periods("2018Q1", "financial_nov")).to eq(
        ["2017Nov"]
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
      expect(described_class.periods("201803", "financial_nov")).to eq(
        ["2017Nov"]
      )
      expect(described_class.periods("201806", "financial_nov")).to eq(
        ["2017Nov"]
      )
      expect(described_class.periods("201807", "financial_nov")).to eq(
        ["2017Nov"]
      )
      expect(described_class.periods("201808", "financial_nov")).to eq(
        ["2017Nov"]
      )
      expect(described_class.periods("201809", "financial_nov")).to eq(
        ["2017Nov"]
      )
      expect(described_class.periods("201810", "financial_nov")).to eq(
        ["2018Nov"]
      )
      expect(described_class.periods("201811", "financial_nov")).to eq(
        ["2018Nov"]
      )
    end
  end
end
