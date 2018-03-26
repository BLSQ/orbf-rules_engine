# frozen_string_literal: true

module Orbf
  module RulesEngine
    class IndicatorEvaluator
      include VariablesBuilderSupport

      def initialize(indicators, dhis2_values)
        @indicators = Array(indicators)
        @indexed_values = Dhis2IndexedValues.new(dhis2_values)
        @period_orgunits = dhis2_values.map do |value|
          [value['period'], value['org_unit'] || value['orgUnit']]
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
          value = indicator_value(period, orgunit, parsed_expressions)
          {
             'dataElement'         => indicator.ext_id,
            'categoryOptionCombo' => 'default',
            'value'               => ValueFormatter.format(value).to_s,
            'period'              => period,
            'orgUnit'             => orgunit
           }
        end
      end

      def sum_values(values)
        values.inject(0) { |sum, v| sum + v['value'].to_f }
      end

      def indicator_value(period, orgunit, parsed_expressions)
        indicator_values = parsed_expressions.flat_map do |expression_to_sum|
          @indexed_values.lookup_values(
            period,
            orgunit,
            expression_to_sum.data_element,
            expression_to_sum.category_combo
          )
        end
        sum_values(indicator_values)
      end
    end
  end
end
