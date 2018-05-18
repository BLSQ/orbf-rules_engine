
RSpec.describe Orbf::RulesEngine::PeriodConverter do
  let(:jan_2017) { Date.parse("01-01-2017") }
  let(:end_mar_2017) { Date.parse("01-03-2017").end_of_month }
  let(:april_2017) { Date.parse("01-04-2017") }
  let(:end_june_2017) { Date.parse("01-06-2017").end_of_month }
  let(:july_2016) { Date.parse("01-07-2016") }
  let(:july_2017) { Date.parse("01-07-2017") }
  let(:end_sept_2017) { Date.parse("01-09-2017").end_of_month }
  let(:oct_2017) { Date.parse("01-10-2017") }
  let(:end_dec_2017) { Date.parse("01-12-2017").end_of_month }
  let(:end_june_2018) { Date.parse("01-06-2018").end_of_month }

  describe "from year month" do
    let(:feb_2017) { Date.parse("01-02-2017") }
    it "transform a month" do
      expect(described_class.as_date_range("201702")).to eq(feb_2017..feb_2017.end_of_month)
    end
  end

  describe "from year" do
    it "transforms year" do
      expect(described_class.as_date_range("2017")).to eq(jan_2017..end_dec_2017)
    end
  end

  describe "from quarters" do
    it "support Q1" do
      expect(described_class.as_date_range("2017Q1")).to eq(jan_2017..end_mar_2017)
    end
    it "support Q2" do
      expect(described_class.as_date_range("2017Q2")).to eq(april_2017..end_june_2017)
    end
    it "support Q3" do
      expect(described_class.as_date_range("2017Q3")).to eq(july_2017..end_sept_2017)
    end
    it "support Q4" do
      expect(described_class.as_date_range("2017Q4")).to eq(oct_2017..end_dec_2017)
    end
  end

  describe "from quarters to financial_july" do
    it "support financial year" do
      expect(described_class.as_date_range("2016July")).to eq(july_2016..end_june_2017)
    end
  end

end
