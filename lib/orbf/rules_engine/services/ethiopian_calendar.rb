module Orbf
  module RulesEngine
    class EthiopianCalendar
      def each_periods(period, frequency, &block)
        EthiopianPeriodIterator.each_periods(period, frequency, &block)
      end

      def periods(period, frequency)
        EthiopianPeriodIterator.periods(period, frequency)
      end
    end
  end
end
