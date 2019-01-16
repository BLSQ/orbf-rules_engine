# frozen_string_literal: true

module Orbf
  module RulesEngine
    class IndicatorEvaluator
      include VariablesBuilderSupport

      def initialize(indicators, dhis2_values)
        @indicators = Array(indicators).uniq
        @indexed_values = Dhis2IndexedValues.new(dhis2_values)
        @period_orgunits = dhis2_values.map do |value|
          [value["period"], value["org_unit"] || value["orgUnit"]]
        end

        @period_orgunits = @period_orgunits.uniq
      end

      def to_dhis2_values
        @indicators.flat_map do |indicator|
          calculate(indicator)
        end
      end

      private

      def calculate(indicator)
        parsed_expressions = IndicatorExpressionParser.parse_expression(indicator.formula)

        @period_orgunits.map do |period, orgunit|
          value = indicator_value(period, orgunit, parsed_expressions, indicator.formula)
          {
            "dataElement"         => indicator.ext_id,
            "categoryOptionCombo" => "default",
            "value"               => value,
            "period"              => period,
            "orgUnit"             => orgunit
          }
        end
      end

      def sum_values(values)
        return "0" if values.empty?

        values.map { |v| v["value"] }.join(" + ")
      end

      def substitute_values(indicator_values, formula)
        indicator_values.each do |expression, data_values|
          expanded_expression = data_values.map { |v| v["value"] }.join(" + ")
          if expanded_expression.length > 0
            formula = formula.gsub(expression, expanded_expression)
          else
            formula = formula.gsub(expression, "0")
          end
        end
        formula
      end

      def indicator_value(period, orgunit, parsed_expressions, formula)
        indicator_values = parsed_expressions.inject({}) do |result, expression|
          result[expression.expression] = @indexed_values.lookup_values(
            period,
            orgunit,
            expression.data_element,
            expression.category_combo
          )
          result
        end
        substitute_values(indicator_values, formula)
      end
    end
  end
end
