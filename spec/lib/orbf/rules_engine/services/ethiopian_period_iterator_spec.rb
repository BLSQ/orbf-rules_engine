RSpec.describe Orbf::RulesEngine::EthiopianPeriodIterator do
  it "converts quarter to months" do
    expect(described_class.periods("2012Q1", "monthly")).to eq(
      %w[201111 201112 201201]
    )
    expect(described_class.periods("2012Q2", "monthly")).to eq(
      %w[201202 201203 201204]
    )
    expect(described_class.periods("2012Q3", "monthly")).to eq(
      %w[201205 201206 201207]
    )
    expect(described_class.periods("2012Q4", "monthly")).to eq(
      %w[201208 201209 201210]
    )
    expect(described_class.periods("2013Q1", "monthly")).to eq(
      %w[201211 201212 201301]
    )
  end

  it "converts quarter to years" do
    # TODO: does it really matches dhis2 ?
    expect(described_class.periods("2012Q1", "yearly")).to eq(
      %w[2011 2012]
    )

    %w[2012Q2 2012Q3 2012Q4].each do |quarter|
      expect(described_class.periods(quarter, "yearly")).to eq(
        %w[2012]
      )
    end
  end

  it "converts year to quarters" do
    expect(described_class.periods("2012", "quarterly")).to eq(
      %w[2012Q1 2012Q2 2012Q3 2012Q4]
    )
  end

  it "converts months to quarter " do
    %w[201201].each do |month|
      expect(described_class.periods(month, "quarterly")).to eq(
        %w[2012Q1]
      )
    end
 

    %w[ 201202 201203 201204 ].each do |month|
       expect(described_class.periods(month, "quarterly")).to eq(
         %w[2012Q2]
       )
     end
     %w[201205 201206 201207 ].each do |month|
       expect(described_class.periods(month, "quarterly")).to eq(
         %w[2012Q3]
       )
     end
     %w[201208 201209 201210].each do |month|
       expect(described_class.periods(month, "quarterly")).to eq(
         %w[2012Q4]
       )
     end
     %w[201211 201212].each do |month|
        expect(described_class.periods(month, "quarterly")).to eq(
          %w[2013Q1]
        )
      end
  end
end
