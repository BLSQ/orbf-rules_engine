# frozen_string_literal: true

module Orbf
  module RulesEngine
    class PeriodsResolver
      def initialize(package, invoice_period)
        @package = package
        @invoice_period = invoice_period
      end

      def call
        from_values_span(package, invoice_period).merge(
          from_package_frequency(package, invoice_period)
        ).to_a
      end

      private

      attr_reader :package, :invoice_period

      def from_package_frequency(package, invoice_period)
        PeriodIterator.periods(invoice_period, package.frequency)
      end

      def from_values_span(package, invoice_period)
        package.rules.flat_map(&:formulas).each_with_object(Set.new) do |formula, set|
          formula.values_dependencies.each do |dependency|
            span = Orbf::RulesEngine::Spans.matching_span(dependency, formula.rule.kind)
            next unless span
            set.merge(span.periods(invoice_period, dependency))
          end
        end
      end
    end
  end
end