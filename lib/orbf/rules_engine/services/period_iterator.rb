# frozen_string_literal: true

module Orbf
  module RulesEngine
    class PeriodIterator
      def self.each_periods(period, frequency, &block)
        periods(period, frequency).each do |p|
          block.call(p)
        end
      end

      def self.periods(period, frequency)
        raise "no support for #{frequency} only #{CLASSES_MAPPING.keys.join(',')}" unless CLASSES_MAPPING.key?(frequency)

        @periods ||= {}
        @periods[[period, frequency]] ||= begin
          date_range = RulesEngine::PeriodConverter.as_date_range(period)
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

      CLASSES_MAPPING = {
        "monthly"        => ExtractMonthlyPeriod,
        "quarterly"      => ExtractQuarterlyPeriod,
        "yearly"         => ExtractYearlyPeriod,
        "financial_july" => ExtractFinancialJulyPeriod
      }.freeze
    end
  end
end
