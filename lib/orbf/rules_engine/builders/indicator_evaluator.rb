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

      # Takes a hash of indicator_values and a formula and will expand
      # the formula to use the values of the indicator_values
      #
      # indicator_values - Hash with as key the data_element.coc and
      #                    as value the value found in dhis2
      # formula - A string with the formula
      #
      # Returns an expanded formula
      def substitute_values(indicator_values, formula)
        # None of the references have any values, return nil
        return nil if indicator_values.values.flatten.empty?

        indicator_values.each do |expression, data_values|
          # Some values, were found, so if a reference now doesn't
          # have any value fill it with 0.
          expanded_values = data_values.map { |v| v["value"] || "0" }

          # If a reference has multiple category combos, expand and
          # sum them but keep them in brackets to ensure it plays nice
          # with / and *
          expanded_expression = if expanded_values.length > 1
                                  "( %s )" % expanded_values.join(" + ")
                                else
                                  expanded_values.join
                                end

          expanded_expression = "0" if expanded_expression.length == 0
          formula = formula.gsub(expression, expanded_expression)
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
