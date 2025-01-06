# the code from #from_iso and #to_iso is a mix of https://github.com/gyohannes/ethiopic_date
# and where we drop custom code to use what Date can offer to manipulate
# Julian day number https://en.wikipedia.org/wiki/Julian_day

module Orbf
  module RulesEngine
    class EthiopianCalendar
      include ::Orbf::RulesEngine::EthiopianConverter

      def support_frequency?(frequency)
        return false if %w[quarterly_nov financial_nov].include?(frequency)

        true
      end

      def to_invoicing_period(year, quarter)
        "#{year}Q#{quarter}"
      end

      def each_periods(period, frequency, &block)
        EthiopianPeriodIterator.each_periods(period, frequency, &block)
      end

      def periods(period, frequency)
        EthiopianPeriodIterator.periods(period, frequency)
      end
    end
  end
end
