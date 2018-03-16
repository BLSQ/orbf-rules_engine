# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Formula
      attr_reader :code, :expression, :comment
      attr_accessor :rule

      def initialize(code, expression, comment = "", single_mapping: nil, activity_mappings: nil)
        @code = code
        @expression = expression.strip
        @comment = comment
        @single_mapping = single_mapping
        @activity_mappings = activity_mappings
        raise "mapping and mappings can't be both filled" if single_mapping && activity_mappings
      end

      def dependencies
        mocked_values = values_dependencies.each_with_object({}) { |k, mocked_values| mocked_values[k.to_sym] = "1" }
        @dependencies ||= CalculatorFactory.build.dependencies(format(expression, mocked_values))
      end

      def values_dependencies
        @values_dependencies ||= Tokenizer.format_keys(@expression).select { |e| e.end_with?("_values") }
      end

      def dhis2_mapping(activity_code = nil)
        return activity_mappings[activity_code] if activity_mappings
        return single_mapping if single_mapping
      end

      private

      attr_reader :single_mapping, :activity_mappings
    end
  end
end
