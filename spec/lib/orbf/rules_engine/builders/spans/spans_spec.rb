


RSpec.describe "spans" do
  it "detect matching dependencies" do
    expect_matching_span(
      "sample_matching_previous_year_values",
      Orbf::RulesEngine::Spans::PreviousYear
    )
    expect_matching_span(
      "sample_matching_previous_year_yearly_values",
      Orbf::RulesEngine::Spans::PreviousYear
    )
    expect_matching_span(
      "sample_matching_previous_year_monthly_values",
      Orbf::RulesEngine::Spans::PreviousYear
    )
  end

  def expect_matching_span(name, clazz)
    expect(Orbf::RulesEngine::Spans.matching_span(name, "activity")).to be_instance_of(clazz)
  end

  describe Orbf::RulesEngine::Spans::PreviousYear do
    let(:span) { described_class.new }
    let(:months) { %w[201501 201502 201503 201504 201505 201506 201507 201508 201509 201510 201511 201512] }
    let(:quarters) { %w[2015Q1 2015Q2 2015Q3 2015Q4] }
    let(:year) { %w[2015] }

    let(:var_name) { "sample_matching_previous_year" }

    it "give prefix" do
      expect(span.prefix("#{var_name}_values")).to eq("sample_matching")
      expect(span.prefix("#{var_name}_monthly_values")).to eq("sample_matching")
      expect(span.prefix("#{var_name}_yearly_values")).to eq("sample_matching")
    end

    it "give periods" do
      expect(span.periods("2016Q1", "#{var_name}_values")).to eq(
        months + quarters + year
      )

      expect(span.periods("2016Q1", "#{var_name}_monthly_values")).to eq(
        months
      )

      expect(span.periods("2016Q1", "#{var_name}_quarterly_values")).to eq(
        quarters
      )

      expect(span.periods("2016Q1", "#{var_name}_yearly_values")).to eq(
        year
      )
    end
  end

  describe Orbf::RulesEngine::Spans::PreviousYearSameQuarter do
    let(:span) { described_class.new }

    let(:var_name) { "sample_matching_previous_year_same_quarter" }

    it "give prefix" do
      expect(span.prefix("#{var_name}_values")).to eq("sample_matching")
      expect(span.prefix("#{var_name}_monthly_values")).to eq("sample_matching")
      expect(span.prefix("#{var_name}_yearly_values")).to eq("sample_matching")
    end

    it "give periods" do
      expect(span.periods("2016Q1", "#{var_name}_values")).to eq(
        %w[201501 201502 201503 2015Q1 2015]
      )

      expect(span.periods("2016Q1", "#{var_name}_monthly_values")).to eq(
        %w[201501 201502 201503]
      )

      expect(span.periods("2016Q1", "#{var_name}_quarterly_values")).to eq(
        ["2015Q1"]
      )

      expect(span.periods("2016Q1", "#{var_name}_yearly_values")).to eq(
        %w[2015]
      )
    end
  end

  describe Orbf::RulesEngine::Spans::PreviousCycle do
    let(:span) { described_class.new }

    it "give prefix" do
      expect(span.prefix("sample_matching_previous_values")).to eq("sample_matching")
    end

    let(:name) { "sample_matching_previous_values" }
    it "give periods" do
      expect(span.periods("201601", name)).to eq(
        []
      )
      expect(span.periods("201602", name)).to eq(
        ["201601"]
      )
      expect(span.periods("201603", name)).to eq(
        %w[201601 201602]
      )
    end
  end
end
