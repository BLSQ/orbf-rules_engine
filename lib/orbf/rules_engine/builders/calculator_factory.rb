# frozen_string_literal: true

require "hesabu"
require "descriptive_statistics/safe"

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
        args = args.flatten
        array = args[0..-2]
        index = args[-1]
        array[index]
      end

      SUM = lambda do |*args|
        args.flatten.inject(0.0) { |acc, elem| acc + elem }
      end

      AVG = lambda do |*args|
        args = args.flatten
        args.flatten.inject(0.0) { |acc, elem| acc + elem } / args.size
      end

      BETWEEN = ->(lower, score, greater) { lower <= score && score <= greater }

      RANDBETWEEN = ->(a, b) { rand(a..b) }

      EVAL_ARRAY = lambda { |key1, array1, key2, array2, meta_formula|
        if array1.length != array2.length
          raise Dentaku::ArgumentError.for(
            :incompatible_type,
            function_name: "EVAL_ARRAY()"
          ), "EVAL_ARRAY() requires '#{key1}' and '#{key2}' in (#{meta_formula}) to have same size of values"
        end
        calc = Dentaku::Calculator.new
        begin
          result = array1.zip(array2).map do |(e1, e2)|
            calc.evaluate!(meta_formula, key1 => e1, key2 => e2)
          end
        rescue Dentaku::UnboundVariableError => e
          bound = quote_keys([key1, key2])
          unbound = quote_keys(e.unbound_variables)

          raise Dentaku::ArgumentError.for(
            :invalid_value,
            function_name: "EVAL_ARRAY()"
          ), "EVAL_ARRAY() #{meta_formula} uses: #{unbound}. We only know: #{bound}"
        end

        result
      }

      ARRAY = ->(*args) { args.flatten }

      SQRT = ->(*args) { Math.sqrt(args[0]) }

      STDEVP = ->(*args) { DescriptiveStatistics.standard_deviation(args) }

      TRUNC = ->(*args) { args[0].truncate(args.length == 2 ? args[1] : 1.0) }

      CEILING = lambda { |*args|
        multiple = args.length == 2 ? args[1] : 1.0
        ((args[0] / multiple).ceil * multiple)
      }

      FLOOR = lambda { |*args|
        multiple = args.length == 2 ? args[1] : 1.0
        ((args[0] / multiple).floor * multiple)
      }

      def self.build(options = { nested_data_support: false, case_sensitive: true })
        Dentaku::Calculator.new(options).tap do |calculator|
          calculator.add_function(:between, :logical, BETWEEN)
          calculator.add_function(:abs, :number, ->(number) { number.abs })
          calculator.add_function(:score_table, :numeric, SCORE_TABLE)
          # Dentaku now has AVG and SUM builtin, as well as ROUNDDOWN and ROUNDUP
          # Their behavior is slightly different.
          #      AVG(1,3,9) => In our function: 4,333333
          #                    In Dentaku: 4.0 (if one of the elements is a float, it does work the same)
          #
          # Since we're mostly using our go-hesabu library, I'm just keeping these as is and ignoring the
          # builtin functions.
          calculator.add_function(:avg, :numeric, AVG)
          calculator.add_function(:sum, :numeric, SUM)
          calculator.add_function(:safe_div, :numeric, SAFE_DIV)
          calculator.add_function(:access, :numeric, ACCESS)
          calculator.add_function(:randbetween, :numeric, RANDBETWEEN)
          calculator.add_function(:eval_array, :array, EVAL_ARRAY)
          calculator.add_function(:array, :array, ARRAY)
          calculator.add_function(:stdevp, :numeric, STDEVP)
          calculator.add_function(:sqrt, :numeric, SQRT)
          calculator.add_function(:trunc, :numeric, TRUNC)
          calculator.add_function(:ceiling, :numeric, CEILING)
          calculator.add_function(:floor, :numeric, FLOOR)
        end
      end

      # quote_keys(['a', 'b']) => "'a', 'b'"
      def self.quote_keys(keys)
        keys.map { |key| "'#{key}'" }.join(", ")
      end
    end

    class CalculatorFactory
      module Hesabu
        class Calculator
          def initialize
            @solver = ::Hesabu::Solver.new
          end

          attr_reader :parser, :interpreter, :solver

          def store(values_hash)
            values_hash.each do |k, v|
              solver.add(k, v.to_s)
            end
          end

          def solve!(values_hash)
            solve(values_hash)
          end

          def solve(values_hash)
            values_hash.each do |k, v|
              solver.add(k, v.to_s)
            end
            solver.solve!
          end
        end
      end

      def self.build(engine_version, options = { nested_data_support: false, case_sensitive: true })
        return LegacyCalculatorFactory.build(options) if engine_version < 3

        Orbf::RulesEngine::CalculatorFactory::Hesabu::Calculator.new
      end

      def self.dependencies(expression)
        return [] if expression.is_a?(Numeric)

        LegacyCalculatorFactory.build.dependencies(expression)
      end
    end
  end
end
