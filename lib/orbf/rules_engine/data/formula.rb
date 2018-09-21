# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Formula
      attr_reader :code, :expression, :comment, :frequency, :exportable_formula_code
      attr_accessor :rule

      def initialize(code, expression, comment = "", single_mapping: nil,
                     activity_mappings: nil, frequency: nil, exportable_formula_code: nil)
        @code = code.strip
        @expression = expression.strip
        @comment = comment
        @frequency = frequency
        @single_mapping = single_mapping
        @activity_mappings = activity_mappings
        @exportable_formula_code = exportable_formula_code
        raise "mapping and mappings can't be both filled" if single_mapping && activity_mappings
      end

      def dependencies
        @dependencies ||= CalculatorFactory.dependencies(format(expression, mocked_values))
      rescue StandardError => e
        raise(e.message + " :" + code + " = " + expression)
      end

      def values_dependencies
        @values_dependencies ||= Tokenizer.format_keys(@expression).select { |e| e.end_with?("_values") }
      end

      def dhis2_mapping(activity_code = nil)
        return activity_mappings[activity_code] if activity_mappings
        return single_mapping if single_mapping
      end

      def data_elements_ids
        if single_mapping
          [single_mapping]
        elsif activity_mappings
          activity_mappings.values
        else
          []
        end
      end

      private

      attr_reader :single_mapping, :activity_mappings

      def mocked_values
        values_dependencies.each_with_object({}) do |k, mocked_value|
          mocked_value[k.to_sym] = "1"
        end
      end
    end
  end
end
