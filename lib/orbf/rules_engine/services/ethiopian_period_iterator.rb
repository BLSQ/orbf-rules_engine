# frozen_string_literal: true

module Orbf
  module RulesEngine
    # Similar to the GregorianPeriodIterator but...
    # The main difference is how the quarters are handled.
    # This mimic the business and dhis2 behaviour for quarterly periods
    # Their definition is offseted by 2 months compared to the gregorian/western way.
    # 2020Q1 => 201911, 201912, 202001
    # 2020Q2 => 202002, 201903, 202004
    # ...
    class EthiopianPeriodIterator
      def self.each_periods(period, frequency, &block)
        periods(period, frequency).each do |p|
          block.call(p)
        end
      end

      def self.periods(period, frequency)
        raise "no support for #{frequency} only #{CLASSES_MAPPING.keys.join(',')}" unless CLASSES_MAPPING.key?(frequency)

        @periods ||= {}
        @periods[[period, frequency]] ||= begin
          date_range = RulesEngine::EthiopianPeriodConverter.as_date_range(period)
          resulting_periods = extract_periods(date_range, frequency)
          resulting_periods.freeze
          resulting_periods
        end
      end

      def self.extract_periods(range, period_type)
        CLASSES_MAPPING[period_type].new(range).call
      end

      class ExtractPeriod < Struct.new(:range)
        def call
          [].tap do |array|
            current_date = first_date
            loop do
              array.push format(current_date)
              current_date = next_date(current_date)
              break if current_date > range.last
            end
          end
        end
      end

      class ExtractMonthlyPeriod < ExtractPeriod
        def next_date(date)
          date.next_month
        end

        def format(date)
          date.strftime("%Y%m")
        end

        def first_date
          range.first.beginning_of_month
        end
      end

      class ExtractQuarterlyPeriod < ExtractPeriod
        def next_date(date)
          date.next_quarter
        end

        def format(date)
          year = date.strftime("%Y")
          quarter = case date.month
                    when 1, 11, 12
                      1
                    when 2, 3, 4
                      2
                    when 5, 6, 7
                      3
                    when 8, 9, 10
                      4
                    end
          year = Integer(year) + 1 if date.month == 11 || date.month == 12
          dhis2_period = "#{year}Q#{quarter}"
          dhis2_period
        end

        def first_date
          range.first
        end
      end

      class ExtractYearlyPeriod < ExtractPeriod
        def next_date(date)
          date.next_year
        end

        def format(date)
          date.strftime("%Y")
        end

        def first_date
          range.first.beginning_of_year
        end
      end

      class ExtractFinancialJulyPeriod < ExtractPeriod
        def next_date(date)
          date.next_year
        end

        def format(date)
          date.strftime("%YJuly")
        end

        def first_date
          anniv_date = range.first.beginning_of_year + 6.months
          range.first < anniv_date ? (anniv_date - 1.year) : anniv_date
        end
      end

      CLASSES_MAPPING = {
        "monthly"        => ExtractMonthlyPeriod,
        "quarterly"      => ExtractQuarterlyPeriod,
        "yearly"         => ExtractYearlyPeriod,
        "financial_july" => ExtractFinancialJulyPeriod
      }.freeze
    end
  end
end
