module Orbf
  module RulesEngine
    class GregorianCalendar
      def each_periods(period, frequency, &block)
        PeriodIterator.each_periods(period, frequency, &block)
      end

      def periods(period, frequency)
        PeriodIterator.periods(period, frequency)
      end
    end
  end
end
