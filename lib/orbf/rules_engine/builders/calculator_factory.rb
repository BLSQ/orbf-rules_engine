# frozen_string_literal: true

require "hesabu"
module Orbf
  module RulesEngine

    class LegacyCalculatorFactory
      SCORE_TABLE = lambda do |*args|
        target = args.shift
        matching_rules = args.each_slice(3).find do |lower, greater, result|
          greater.nil? || result.nil? ? true : lower <= target && target < greater
        end
        matching_rules.last
      end

      SAFE_DIV = lambda do |*args|
        dividend = args[0]
        divisor = args[1]
        divisor.zero? ? 0 : (dividend.to_f / divisor.to_f)
      end

      ACCESS = lambda do |*args|
        array = args[0..-2]
        index = args[-1]
        array[index]
      end

      SUM = lambda do |*args|
        args.inject(0.0) { |acc, elem| acc + elem }
      end

      AVG = lambda do |*args|
        args.inject(0.0) { |acc, elem| acc + elem } / args.size
      end

      BETWEEN = ->(lower, score, greater) { lower <= score && score <= greater }

      RANDBETWEEN = ->(a, b) { rand(a..b) }

      def self.build(options = { nested_data_support: false, case_sensitive: true })
        Dentaku::Calculator.new(options).tap do |calculator|
          calculator.add_function(:between, :logical, BETWEEN)
          calculator.add_function(:abs, :number, ->(number) { number.abs })
          calculator.add_function(:score_table, :numeric, SCORE_TABLE)
          calculator.add_function(:avg, :numeric, AVG)
          calculator.add_function(:sum, :numeric, SUM)
          calculator.add_function(:safe_div, :numeric, SAFE_DIV)
          calculator.add_function(:access, :numeric, ACCESS)
          calculator.add_function(:randbetween, :numeric, RANDBETWEEN)
        end
      end
    end


    class CalculatorFactory
      module Hesabu
        class Calculator
          def initialize
            @solver = ::Hesabu::Solver.new
          end

          attr_reader :parser, :interpreter, :solver

          def dependencies(expression)
            if expression.is_a?(Numeric)
              return []
            end
            LegacyCalculatorFactory.build().dependencies(expression)
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
