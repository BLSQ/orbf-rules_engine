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
        ).merge(from_forced_quarterly_access(package, invoice_period)).to_a
      end

      private

      attr_reader :package, :invoice_period

      def from_package_frequency(package, invoice_period)
        package.calendar.periods(invoice_period, package.frequency) +
          package.calendar.periods(invoice_period, "yearly") +
          package.calendar.periods(invoice_period, "financial_july")
      end

      def from_values_span(package, invoice_period)
        package.rules.flat_map(&:formulas).each_with_object(Set.new) do |formula, set|
          formula.values_dependencies.each do |dependency|
            span = Orbf::RulesEngine::Spans.matching_span(dependency, formula.rule.kind)
            next unless span

            set.merge(span.periods(invoice_period, dependency, package.calendar))
          end
        end
      end

      def from_forced_quarterly_access(package, invoice_period)
        return [] if package.frequency != "monthly"

        dependencies = package.activity_rules.flat_map(&:formulas).flat_map(&:dependencies)

        levels = 1..7
        level_states_enum = levels.flat_map do |level|
          package.states.to_a.map {|state| "#{state}_level_#{level}_quarterly"}
        end
        level_states_quarterly = Set.new(level_states_enum)
        
        if dependencies.any? { |dependency| level_states_quarterly.include?(dependency)  }
          return package.calendar.periods(invoice_period, "quarterly")
        end 

        []        
      end
    end
  end
end
