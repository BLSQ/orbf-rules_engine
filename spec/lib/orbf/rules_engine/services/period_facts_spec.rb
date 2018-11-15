RSpec.describe Orbf::RulesEngine::PeriodFacts do
  let(:facts) { Orbf::RulesEngine::PeriodFacts }

  it "works for quarter" do
    expect(facts.for("2016Q1")).to eq("quarter_of_year" => "1", "month_of_year" => "3", "month_of_quarter" => "3")
    expect(facts.for("2016Q2")).to eq("quarter_of_year" => "2", "month_of_year" => "6", "month_of_quarter" => "3")
    expect(facts.for("2016Q3")).to eq("quarter_of_year" => "3", "month_of_year" => "9", "month_of_quarter" => "3")
    expect(facts.for("2016Q4")).to eq("quarter_of_year" => "4", "month_of_year" => "12", "month_of_quarter" => "3")
  end

  it "works for months" do
    expect(facts.for("201601")).to eq("quarter_of_year" => "1", "month_of_year" => "1", "month_of_quarter" => "1")
    expect(facts.for("201602")).to eq("quarter_of_year" => "1", "month_of_year" => "2", "month_of_quarter" => "2")
    expect(facts.for("201603")).to eq("quarter_of_year" => "1", "month_of_year" => "3", "month_of_quarter" => "3")

    expect(facts.for("201604")).to eq("quarter_of_year" => "2", "month_of_year" => "4", "month_of_quarter" => "1")
    expect(facts.for("201605")).to eq("quarter_of_year" => "2", "month_of_year" => "5", "month_of_quarter" => "2")
    expect(facts.for("201606")).to eq("quarter_of_year" => "2", "month_of_year" => "6", "month_of_quarter" => "3")

    expect(facts.for("201607")).to eq("quarter_of_year" => "3", "month_of_year" => "7", "month_of_quarter" => "1")
    expect(facts.for("201608")).to eq("quarter_of_year" => "3", "month_of_year" => "8", "month_of_quarter" => "2")
    expect(facts.for("201609")).to eq("quarter_of_year" => "3", "month_of_year" => "9", "month_of_quarter" => "3")

    expect(facts.for("201610")).to eq("quarter_of_year" => "4", "month_of_year" => "10", "month_of_quarter" => "1")
    expect(facts.for("201611")).to eq("quarter_of_year" => "4", "month_of_year" => "11", "month_of_quarter" => "2")
    expect(facts.for("201612")).to eq("quarter_of_year" => "4", "month_of_year" => "12", "month_of_quarter" => "3")
  end
end
