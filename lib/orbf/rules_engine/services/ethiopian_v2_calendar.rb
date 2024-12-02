module Orbf
  module RulesEngine
    class EthiopianV2Calendar
      include Orbf::RulesEngine::EthiopianConverter

      def support_frequency?(_frequency)
        true
      end

      def to_invoicing_period(year, quarter)
        "#{year}NovQ#{quarter}"
      end

      def each_periods(period, frequency, &block)
        PeriodIterator.each_periods(period, frequency, &block)
      end

      def periods(period, frequency)
        PeriodIterator.periods(period, frequency)
      end
    end
  end
end
