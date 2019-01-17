# frozen_string_literal: true

module Orbf
  module RulesEngine
    class IndicatorExpression < Orbf::RulesEngine::ValueObject
      attributes :expression, :data_element, :category_combo
      attr_reader :expression, :data_element, :category_combo
      def initialize(expression: nil, data_element: nil, category_combo: nil)
        @expression = expression
        @data_element = data_element
        @category_combo = category_combo
        freeze
      end
    end

    class UnsupportedFormulaException < StandardError
      attr_reader :formula, :unsupported
      def initialize(formula, unsupported)
        @formula = formula
        @unsupported = unsupported
        super("Unsupported syntax '#{@unsupported}' in '#{formula}'")
      end
    end

    class IndicatorExpressionParser
      #  currenty only support sum like  '#{dhjgLt7EYmu.se1qWfbtkmx}+#{xtVtnuWBBLB}'
      UNSUPPORTED_FEATURES = ["C{", "OUG{", "R{"].freeze
      SUPPORTED_FEATURE = "+"

      class << self
        def parse_expression(formula)
          unsupported = UNSUPPORTED_FEATURES.find { |f| formula.include?(f) }
          raise UnsupportedFormulaException.new(formula, unsupported) if unsupported

          tokens = formula.scan(/\#{([[a-zA-Z0-9.]]+)}/).reject(&:empty?).flatten
          raise UnsupportedFormulaException.new(formula, "Constants without data_elements") if tokens.empty?

          tokens.map do |token|
            to_indicator_expression(token)
          end
        end

        private

        def to_indicator_expression(expression)
          data_element_category =  expression.sub('#{', "").sub("}", "")
          data_element, category = data_element_category.split(".").map(&:strip)
          IndicatorExpression.new(
            expression:     '#{' + expression.strip + '}',
            data_element:   data_element,
            category_combo: category
          )
        end
      end
    end
  end
end
