# frozen_string_literal: true

module Orbf
  module RulesEngine
    class ActivityFormulaValuesExpander
      include VariablesBuilderSupport

      def initialize(package_code, activity_code, formula, orgunit, period)
        @package_code = package_code
        @activity_code = activity_code
        @formula = formula
        @orgunit = orgunit
        @period = period
      end

      # turn %{..._values} in to their :
      #    activity_code_code_for_orgunit_id_and_period_1,
      #    activity_code_code_for_orgunit_id_and_period_2
      # in the expression formula for a given orgunit, period and activity code
      def expand_values
        expanded_string = formula.expression
        spans_subsitutions.each do |k, v|
          expanded_string = expanded_string.gsub("%{#{k}}", v)
        end
        expanded_string
      end

      private

      attr_reader :package_code, :activity_code, :formula, :orgunit, :period

      # return hash with values to susbstitute in the formula
      #   key is dependency symbol and values is the joined values
      #       activity_code_code_for_orgunit_id_and_period_1,
      #       activity_code_code_for_orgunit_id_and_period_2
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
          suffix_for_id_activity(package_code, activity_code, code, orgunit.ext_id, period)
        end
        val.join(",")
      end
    end
  end
end
