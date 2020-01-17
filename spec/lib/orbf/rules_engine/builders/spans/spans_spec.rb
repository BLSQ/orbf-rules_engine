RSpec.describe "spans" do
  let(:cal) { Orbf::RulesEngine::GregorianCalendar.new }

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
      expect(span.periods("2016Q1", "#{var_name}_values", cal)).to eq(
        months + quarters + year
      )

      expect(span.periods("2016Q1", "#{var_name}_monthly_values", cal)).to eq(
        months
      )

      expect(span.periods("2016Q1", "#{var_name}_quarterly_values", cal)).to eq(
        quarters
      )

      expect(span.periods("2016Q1", "#{var_name}_yearly_values", cal)).to eq(
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
      expect(span.periods("2016Q1", "#{var_name}_values", cal)).to eq(
        %w[201501 201502 201503 2015Q1 2015]
      )

      expect(span.periods("2016Q1", "#{var_name}_monthly_values", cal)).to eq(
        %w[201501 201502 201503]
      )

      expect(span.periods("2016Q1", "#{var_name}_quarterly_values", cal)).to eq(
        ["2015Q1"]
      )

      expect(span.periods("2016Q1", "#{var_name}_yearly_values", cal)).to eq(
        %w[2015]
      )
    end
  end

  describe Orbf::RulesEngine::Spans::CurrentQuarter do
    let(:span) { described_class.new }

    let(:var_name) { "sample_matching_current_quarter" }

    it "give prefix" do
      expect(span.prefix("#{var_name}_values")).to eq("sample_matching")
      expect(span.prefix("#{var_name}_monthly_values")).to eq("sample_matching")
      expect(span.prefix("#{var_name}_yearly_values")).to eq("sample_matching")
    end

    it "give periods" do
      expect(span.periods("2016Q1", "#{var_name}_values", cal)).to eq(
        %w[201601 201602 201603]
      )

      expect(span.periods("2016Q1", "#{var_name}_monthly_values", cal)).to eq(
        %w[201601 201602 201603]
      )

      expect(span.periods("2016Q1", "#{var_name}_quarterly_values", cal)).to eq(
        %w[2016Q1]
      )

      expect(span.periods("2016Q1", "#{var_name}_yearly_values", cal)).to eq(
        %w[2016]
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
      expect(span.periods("201601", name, cal)).to eq(
        []
      )
      expect(span.periods("201602", name, cal)).to eq(
        ["201601"]
      )
      expect(span.periods("201603", name, cal)).to eq(
        %w[201601 201602]
      )
    end
  end


  describe Orbf::RulesEngine::Spans::SlidingWindow do
    let(:span) { described_class.new }

    describe ".matching_span" do
      it "matches when needed" do
        expect_matching_span(
          "sample_matching_last_6_months_window_values",
          Orbf::RulesEngine::Spans::SlidingWindow
        )
      end

      it "does not match when not needed" do
        expect(Orbf::RulesEngine::Spans.matching_span("sample_matching_last_but_not_least", "activity")).to_not be_instance_of(described_class)
      end
    end

    it "give prefix" do
      expect(span.prefix("sample_matching_last_2_months_window_values")).to eq("sample_matching")
    end

    let(:name) { "sample_matching" }

    it "give periods" do
      expect(span.periods("201601", "#{name}_last_6_months_window_values", cal)).to eq(
        %w[
          201508
          201509
          201510
          201511
          201512
          201601
        ]
      )
    end

    [
      ["last_2_quarters", %w[2015Q4 2016Q1]],
      ["last_2_quarters_exclusive", %w[2015Q3 2015Q4]],
      ["last_1_quarters", %w[2016Q1]],
      ["last_1_quarters_exclusive", %w[2015Q4]],
      ["last_3_quarters_exclusive", %w[2015Q2 2015Q3 2015Q4]],
      ["last_3_months", %w[201511 201512 201601]],
      ["last_2_months_exclusive", %w[201511 201512]]
    ].each do |suffix, expected|

      it "#{suffix}_window_values for 2016Q1 should return #{expected}" do
        expect(span.periods("2016Q1", "#{name}_#{suffix}_window_values", cal)).to eq(
          expected
        )
      end
    end

    it "should fail fast on invalid modifier" do
      expect { span.periods("2016Q1", "#{name}_last_3_months_unknown_window_values", cal) }.to(
        raise_error("Sorry unsupported modifier mode : sample_matching_last_3_months_unknown_window_values")
      )
    end

    it "should fail fast on invalid period unit" do
      expect { span.periods("2016Q1", "#{name}_last_3_weeks_exclusive_window_values", cal) }.to(
        raise_error("Sorry 'weeks' is not supported only months and quarters in sample_matching_last_3_weeks_exclusive_window_values")
      )
    end
  end
end
