# frozen_string_literal: true

require "byebug"

module Orbf
  module RulesEngine
    QUARTERLY_NOV_MONTH_TO_Q = {
      1  => { quarter: 1, first_month: 11, year: 0 },
      12 => { quarter: 1, first_month: 11, year: 1 },
      11 => { quarter: 1, first_month: 11, year: 1 },

      10 => { quarter: 4, first_month: 8, year: 0},
      9  => { quarter: 4, first_month: 8, year: 0 },
      8  => { quarter: 4, first_month: 8, year: 0 },

      7  => { quarter: 3, first_month: 6, year: 0 },
      6  => { quarter: 3, first_month: 6, year: 0 },
      5  => { quarter: 3, first_month: 6, year: 0 },

      4  => { quarter: 2, first_month: 2, year: 0 },
      3  => { quarter: 2, first_month: 2, year: 0 },
      2  => { quarter: 2, first_month: 2, year: 0 }

    }
    class PeriodIterator
      def self.each_periods(period, frequency, &block)
        periods(period, frequency).each do |p|
          block.call(p)
        end
      end

      def self.periods(period, frequency)
        unless CLASSES_MAPPING.key?(frequency)
          raise "no support for #{frequency} only #{CLASSES_MAPPING.keys.join(',')}"
        end

        @periods ||= {}
        @periods[[period, frequency]] ||= begin
          date_range = RulesEngine::PeriodConverter.as_date_range(period)
          puts "#{frequency}\t#{period} => #{date_range}"
          resulting_periods = extract_periods(date_range, frequency)
          puts "#{frequency}\t#{period} => #{resulting_periods} vs #{date_range}"
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

      class ExtractQuarterlyNovPeriod < ExtractPeriod
        def next_date(date)
          date + 3.month
        end

        def format(date)
          offsets_def = QUARTERLY_NOV_MONTH_TO_Q[date.month]
          year = date.strftime("%Y").to_i + offsets_def[:year]
          year.to_s+ "NovQ" + offsets_def[:quarter].to_s
        end

        def first_date
          offsets_def = QUARTERLY_NOV_MONTH_TO_Q[range.first.month]
          result = range.first.change(month: offsets_def[:first_month])
          puts("first_date : #{range.first.month} #{result} #{range}")
          result
        end
      end

      class ExtractQuarterlyPeriod < ExtractPeriod
        def next_date(date)
          date.next_quarter
        end

        def format(date)
          date.strftime("%Y") + "Q" + (date.month / 3.0).ceil.to_s
        end

        def first_date
          range.first.beginning_of_quarter
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

      class ExtractFinancialNovPeriod < ExtractPeriod
        def next_date(date)
          result = date + 12.months          
          result
        end

        def format(date)
          date.strftime("%YNov")
        end

        def first_date
          anniv_date = range.first.beginning_of_year + 10.months
          result = range.first < anniv_date ? (anniv_date  ) : anniv_date + 1.year
          result
        end
      end

      CLASSES_MAPPING = {
        "monthly"        => ExtractMonthlyPeriod,
        "quarterly_nov"  => ExtractQuarterlyNovPeriod,
        "quarterly"      => ExtractQuarterlyPeriod,
        "yearly"         => ExtractYearlyPeriod,
        "financial_july" => ExtractFinancialJulyPeriod,
        "financial_nov"  => ExtractFinancialNovPeriod
      }.freeze
    end
  end
end
