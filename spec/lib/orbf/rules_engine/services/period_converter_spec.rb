
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
    it "support financial year july" do
      expect(described_class.as_date_range("2016July")).to eq(july_2016..end_june_2017)
    end
  end

  describe "from financial_nov" do
    let(:novembre_2015) { Date.parse("01-11-2015") }
    let(:end_octobre_2016){ Date.parse("01-10-2016").end_of_month }
    it "support financial year nov" do
      expect(described_class.as_date_range("2016Nov")).to eq(novembre_2015..end_octobre_2016)
    end
  end

  describe "from quarterly nov" do

    let(:novembre_2015) { Date.parse("01-11-2015") }
    let(:end_janvier_2016) { Date.parse("01-01-2016").end_of_month }

    let(:fev_2016){ Date.parse("01-02-2016") }
    let(:end_avril_2016){ Date.parse("01-04-2016").end_of_month }

    let(:mai_2016){ Date.parse("01-05-2016") }
    let(:end_juillet_2016){ Date.parse("01-07-2016").end_of_month }

    let(:aout_2016){ Date.parse("01-08-2016") }
    let(:end_octobre_2016){ Date.parse("01-10-2016").end_of_month }


    it "support quarerly nov 1" do
      expect(described_class.as_date_range("2016NovQ1")).to eq(novembre_2015..end_janvier_2016)
    end

    it "support quarerly nov 2" do
      expect(described_class.as_date_range("2016NovQ2")).to eq(fev_2016..end_avril_2016)
    end
    it "support quarerly nov 3" do
      expect(described_class.as_date_range("2016NovQ3")).to eq(mai_2016..end_juillet_2016)
    end
    it "support quarerly nov 4" do
      expect(described_class.as_date_range("2016NovQ4")).to eq(aout_2016..end_octobre_2016)
    end
  end
end
