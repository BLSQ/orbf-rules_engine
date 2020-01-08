
# frozen_string_literal: true

module Orbf
  module RulesEngine
    class PeriodFacts
      def self.for(period, calendar)
        year = calendar.periods(period, "yearly").last
        month = calendar.periods(period, "monthly").last
        quarter = calendar.periods(period, "quarterly").last

        month_of_quarter = calendar.periods(quarter, "monthly").index(month) + 1
        month_of_year = calendar.periods(year, "monthly").index(month) + 1

        quarter_of_year = calendar.periods(year, "quarterly").index(quarter) + 1

        {
          "quarter_of_year"  => quarter_of_year.to_s,
          "month_of_year"    => month_of_year.to_s,
          "month_of_quarter" => month_of_quarter.to_s
        }.freeze
      end
    end
  end
end
