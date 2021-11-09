require "date"

RSpec.describe Orbf::RulesEngine::EthiopianCalendar do
  let(:cal) { Orbf::RulesEngine::EthiopianCalendar.new }

  def expect_to_ethiopian(year, month, expected)
    gregorian = Date.new(year, month, 1)
    date = cal.from_iso(gregorian)
    expect(date.strftime("%Y%m")).to eq(expected)
  end

  it "converts from iso to ethiopian (omits month 13)" do
    expect_to_ethiopian(2019, 1, "201104")
    expect_to_ethiopian(2019, 2, "201105")
    expect_to_ethiopian(2019, 3, "201106")
    expect_to_ethiopian(2019, 4, "201107")
    expect_to_ethiopian(2019, 5, "201108")
    expect_to_ethiopian(2019, 6, "201109")
    expect_to_ethiopian(2019, 7, "201110")
    expect_to_ethiopian(2019, 8, "201111")
    expect_to_ethiopian(2019, 9, "201112")
    expect_to_ethiopian(2019, 10, "201201")
    expect_to_ethiopian(2019, 11, "201202")
    expect_to_ethiopian(2019, 12, "201203")
  end

  it "converts from ethiopian to iso" do
    expect_from_ethiopian(2011, 4, "201812")
    expect_from_ethiopian(2011, 5, "201901")
    expect_from_ethiopian(2011, 6, "201902")
    expect_from_ethiopian(2011, 7, "201903")
  end

  it "symetric" do
    gregorian = Date.new(2019, 0o7, 1)
    ethiopian = cal.from_iso(gregorian)
    gregorian2 = cal.to_iso(ethiopian)

    expect(gregorian).to eq(gregorian2)
  end


  it "works on bisextile a bit before" do 
    gregorian = Date.new(2021, 11, 7)
    ethiopian = cal.from_iso(gregorian)
    gregorian2 = cal.to_iso(ethiopian)
    expect(gregorian).to eq(gregorian2)
  end  


  it "works on bisextile and silently offset by 1 day" do 
    gregorian = Date.new(2021, 11, 8)
    ethiopian = cal.from_iso(gregorian)
    gregorian2 = cal.to_iso(ethiopian)
    expect(Date.new(2021, 11, 7)).to eq(gregorian2)
  end

  it "works on bisextile and silently offset by 2 day" do 
    gregorian = Date.new(2021, 11, 9)
    ethiopian = cal.from_iso(gregorian)
    gregorian2 = cal.to_iso(ethiopian)
    expect(Date.new(2021, 11, 7)).to eq(gregorian2)
  end  

  it "works on bisextile a bit after" do 
    gregorian = Date.new(2021, 11, 10)
    ethiopian = cal.from_iso(gregorian)
    gregorian2 = cal.to_iso(ethiopian)
    expect(gregorian).to eq(gregorian2)
  end  


  def expect_from_ethiopian(year, month, expected)
    ethiopian = Date.new(year, month, 1)
    date = cal.to_iso(ethiopian)
    expect(date.strftime("%Y%m")).to eq(expected)
  end
end
