# frozen_string_literal: true

require "hesabu"
module Orbf
  module RulesEngine
    class CalculatorFactory
      module Hesabu
        class Calculator
          def initialize
            @parser = ::Hesabu::Parser.new
            @interpreter = ::Hesabu::Interpreter.new
            @solver = ::Hesabu::Solver.new
          end

          attr_reader :parser, :interpreter, :solver

          def dependencies(expression)
            if expression.is_a?(Numeric)
              return []
            end
            ast_tree = begin
              @parser.parse(expression.gsub(/\r\n?/, ""))

            rescue Parslet::ParseFailed => e
              raise "failed to parse #{expression} : #{e.message}"
            end
            bindings = {}
            var_identifiers = Set.new
            interpretation = @interpreter.apply(
              ast_tree,
              doc:             bindings,
              var_identifiers: var_identifiers
            )
            var_identifiers.to_a
          end

          def store(values_hash)
            values_hash.each do |k, v|
              solver.add(k, v.to_s)
            end
          end

          def solve(values_hash)
            values_hash.each do |k, v|
              solver.add(k, v.to_s)
            end
            solver.solve!
          end
        end
      end

      def self.build(_options = { nested_data_support: false, case_sensitive: true })
        Orbf::RulesEngine::CalculatorFactory::Hesabu::Calculator.new
      end
    end
  end
end
