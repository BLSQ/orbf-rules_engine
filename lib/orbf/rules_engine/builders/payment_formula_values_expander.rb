# frozen_string_literal: true

module Orbf
  module RulesEngine
    class PaymentFormulaValuesExpander
      include VariablesBuilderSupport

      def initialize(payment_rule_code:, formula:, orgunit:, period:)
        @payment_rule_code = payment_rule_code
        @formula = formula
        @orgunit = orgunit
        @period = period
      end

      # turn %{..._values} in to their :
      #    code_for_orgunit_id_and_period_1,
      #    code_for_orgunit_id_and_period_2
      # in the expression formula for a given orgunit, period and activity code
      def expand_values
        format(formula.expression, spans_subsitutions)
      end

      private

      attr_reader :payment_rule_code, :formula, :orgunit, :period

      # return hash with values to susbstitute in the formula
      #   key is dependency symbol and values is the joined values
      #       code_for_orgunit_id_and_period_1,
      #       code_for_orgunit_id_and_period_2
      def spans_subsitutions
        formula.values_dependencies.each_with_object({}) do |dependency, hash|
          span = Orbf::RulesEngine::Spans.matching_span(dependency, formula.rule.kind)
          next unless span
          next if hash[dependency.to_sym]

          hash[dependency.to_sym] = to_values_list(span, dependency)
        end
      end

      def to_values_list(span, dependency)
        periods = span.periods(period, dependency)
        code = span.prefix(dependency)
        val = periods.map do |period|
          suffix_for_package(payment_rule_code, code, orgunit, period)
        end
        val.empty? ? '0' : val.join(', ')
      end
    end
  end
end
