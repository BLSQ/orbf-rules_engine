RSpec.describe Orbf::RulesEngine::PeriodFacts do
  describe "with gregorian calendar" do
    let(:facts) { Orbf::RulesEngine::PeriodFacts }
    let(:cal) { Orbf::RulesEngine::GregorianCalendar.new }

    it "works for quarter" do
      expect(facts.for("2016Q1", cal)).to eq("year" => "2016", "quarter_of_year" => "1", "month_of_year" => "3", "month_of_quarter" => "3")
      expect(facts.for("2016Q2", cal)).to eq("year" => "2016", "quarter_of_year" => "2", "month_of_year" => "6", "month_of_quarter" => "3")
      expect(facts.for("2016Q3", cal)).to eq("year" => "2016", "quarter_of_year" => "3", "month_of_year" => "9", "month_of_quarter" => "3")
      expect(facts.for("2016Q4", cal)).to eq("year" => "2016", "quarter_of_year" => "4", "month_of_year" => "12", "month_of_quarter" => "3")
    end

    it "works for months" do
      expect(facts.for("201601", cal)).to eq("year" => "2016", "quarter_of_year" => "1", "month_of_year" => "1", "month_of_quarter" => "1")
      expect(facts.for("201602", cal)).to eq("year" => "2016", "quarter_of_year" => "1", "month_of_year" => "2", "month_of_quarter" => "2")
      expect(facts.for("201603", cal)).to eq("year" => "2016", "quarter_of_year" => "1", "month_of_year" => "3", "month_of_quarter" => "3")

      expect(facts.for("201604", cal)).to eq("year" => "2016", "quarter_of_year" => "2", "month_of_year" => "4", "month_of_quarter" => "1")
      expect(facts.for("201605", cal)).to eq("year" => "2016", "quarter_of_year" => "2", "month_of_year" => "5", "month_of_quarter" => "2")
      expect(facts.for("201606", cal)).to eq("year" => "2016", "quarter_of_year" => "2", "month_of_year" => "6", "month_of_quarter" => "3")

      expect(facts.for("201607", cal)).to eq("year" => "2016", "quarter_of_year" => "3", "month_of_year" => "7", "month_of_quarter" => "1")
      expect(facts.for("201608", cal)).to eq("year" => "2016", "quarter_of_year" => "3", "month_of_year" => "8", "month_of_quarter" => "2")
      expect(facts.for("201609", cal)).to eq("year" => "2016", "quarter_of_year" => "3", "month_of_year" => "9", "month_of_quarter" => "3")

      expect(facts.for("201610", cal)).to eq("year" => "2016", "quarter_of_year" => "4", "month_of_year" => "10", "month_of_quarter" => "1")
      expect(facts.for("201611", cal)).to eq("year" => "2016", "quarter_of_year" => "4", "month_of_year" => "11", "month_of_quarter" => "2")
      expect(facts.for("201612", cal)).to eq("year" => "2016", "quarter_of_year" => "4", "month_of_year" => "12", "month_of_quarter" => "3")
    end
  end

  describe "with ethiopian calendar" do
    let(:facts) { Orbf::RulesEngine::PeriodFacts }
    let(:cal) { Orbf::RulesEngine::EthiopianCalendar.new }

    it "works for quarter" do
      expect(facts.for("2016Q1", cal)).to eq("year" => "2016", "quarter_of_year" => "1", "month_of_year" => "1", "month_of_quarter" => "3")
      expect(facts.for("2016Q2", cal)).to eq("year" => "2016", "quarter_of_year" => "2", "month_of_year" => "4", "month_of_quarter" => "3")
      expect(facts.for("2016Q3", cal)).to eq("year" => "2016", "quarter_of_year" => "3", "month_of_year" => "7", "month_of_quarter" => "3")
      expect(facts.for("2016Q4", cal)).to eq("year" => "2016", "quarter_of_year" => "4", "month_of_year" => "10", "month_of_quarter" => "3")
    end

    it "works for months" do
      expect(facts.for("201601", cal)).to eq("year" => "2016", "quarter_of_year" => "1", "month_of_year" => "1", "month_of_quarter" => "3")

      expect(facts.for("201602", cal)).to eq("year" => "2016", "quarter_of_year" => "2", "month_of_year" => "2", "month_of_quarter" => "1")
      expect(facts.for("201603", cal)).to eq("year" => "2016", "quarter_of_year" => "2", "month_of_year" => "3", "month_of_quarter" => "2")
      expect(facts.for("201604", cal)).to eq("year" => "2016", "quarter_of_year" => "2", "month_of_year" => "4", "month_of_quarter" => "3")

      expect(facts.for("201605", cal)).to eq("year" => "2016", "quarter_of_year" => "3", "month_of_year" => "5", "month_of_quarter" => "1")
      expect(facts.for("201606", cal)).to eq("year" => "2016", "quarter_of_year" => "3", "month_of_year" => "6", "month_of_quarter" => "2")
      expect(facts.for("201607", cal)).to eq("year" => "2016", "quarter_of_year" => "3", "month_of_year" => "7", "month_of_quarter" => "3")

      expect(facts.for("201608", cal)).to eq("year" => "2016", "quarter_of_year" => "4", "month_of_year" => "8", "month_of_quarter" => "1")
      expect(facts.for("201609", cal)).to eq("year" => "2016", "quarter_of_year" => "4", "month_of_year" => "9", "month_of_quarter" => "2")
      expect(facts.for("201610", cal)).to eq("year" => "2016", "quarter_of_year" => "4", "month_of_year" => "10", "month_of_quarter" => "3")

      expect(facts.for("201611", cal)).to eq("year" => "2016", "quarter_of_year" => "1", "month_of_year" => "11", "month_of_quarter" => "1")
      expect(facts.for("201612", cal)).to eq("year" => "2016", "quarter_of_year" => "1", "month_of_year" => "12", "month_of_quarter" => "2")
    end
  end
end
