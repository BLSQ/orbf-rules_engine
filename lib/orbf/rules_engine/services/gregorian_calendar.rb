module Orbf
  module RulesEngine
    class GregorianCalendar

      def support_frequency?(frequency)
        if frequency == "quarterly_nov" || frequency == "financial_nov" 
          return false
        end
        return true
      end

      def to_invoicing_period(year, quarter)
        "#{year}Q#{quarter}"
      end

      def each_periods(period, frequency, &block)
        PeriodIterator.each_periods(period, frequency, &block)
      end

      def periods(period, frequency)
        PeriodIterator.periods(period, frequency)
      end

      def from_iso(date)
        date
      end

      def to_iso(date)
        date
      end

    end
  end
end
