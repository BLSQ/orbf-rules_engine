# frozen_string_literal: true

module Orbf
  module RulesEngine
    class PeriodConverter
      def self.as_date_range(period)
        PARSERS.each do |parser|
          date_range = parser.from(period)
          return date_range if date_range
        end
        raise "unsupported period format : '#{period}'"
      end

      class YearParser
        def self.from(period)
          return unless period.length == 4

          year = period[0..3]
          start_date = Date.parse("#{year}-01-01")
          end_date = start_date.end_of_year

          start_date..end_date
        end
      end

      class YearQuarterParser
        def self.from(period)
          return unless period.length == 6
          return unless period.include?("Q")

          components = period.split("Q")
          quarter = Integer(components.last)
          year = Integer(components.first)
          month = (3 * (quarter - 1)) + 1
          start_date = Date.parse("#{year}-#{month}-01")

          start_date..start_date.end_of_quarter
        end
      end

      class YearQuarterNovParser
        def self.from(period)
          return unless period.length == 9
          return unless period.include?("NovQ")

          components = period.split("NovQ")
          quarter = Integer(components.last)
          year = Integer(components.first)
          month = (3 * (quarter - 1))
          # we start from november
          start_date = Date.parse("#{year}-11-01")+ month.months
          # can't use end_of_quarter since quarters are offset of 1 month
          end_date = start_date + 3.months - 1.day 
          start_date..end_date
        end
      end

      class YearMonthParser
        def self.from(period)
          return unless period.length == 6

          year = period[0..3]
          month = period[4..5].to_i
          start_date = Date.parse("#{year}-#{month}-01")
          end_date = start_date.end_of_month

          start_date..end_date
        end
      end

      class FinancialJulyParser
        def self.from(period)
          return unless period.length == 8
          return unless period.include?("July")

          year = period[0..3]
          month = 7
          start_date = Date.parse("#{year}-#{month}-01")
          end_date = (start_date - 1.day).end_of_month + 1.year

          start_date..end_date
        end
      end

      class FinancialNovParser
        def self.from(period)
          return unless period.length == 7
          return unless period.include?("Nov")

          year = period[0..3]
          month = 11
          start_date = Date.parse("#{year}-#{month}-01")
          end_date = (start_date - 1.day).end_of_month + 1.year

          start_date..end_date
        end
      end

      PARSERS = [YearParser, YearQuarterParser, YearQuarterNovParser, YearMonthParser, FinancialJulyParser,
                 FinancialNovParser].freeze
    end
  end
end
