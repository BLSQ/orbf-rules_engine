
# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Solver
      attr_reader :variables, :solution, :timings, :equations

      def initialize
        @variables = []
        @timings = {}
      end

      def register_variables(vars)
        @variables.push(*vars)
        duplicates = @variables.group_by(&:key).select { |_, vals| vals.size > 1 }
        raise duplicate_message(duplicates, vars) if duplicates.any?
      end

      def build_problem
        variables.each_with_object({}) do |variable, hash|
          hash[variable.key] = variable.expression
        end
      end

      def solve!
        problem = benchmark("build_time") do
          build_problem
        end

        begin
          benchmark("solve_time") do
            solve(problem)
          end
          RulesEngine::Log.call [
            "***** problem ",
            JSON.pretty_generate(problem),
            "**** solution ",
            JSON.pretty_generate(solution.map { |k, v| [k, v.to_f] }.to_h),
            " #{benchmark_log} : problem size=#{problem.size} (#{equations.size})"
          ].join("\n")
        rescue StandardError => e
          RulesEngine::Log.error([
            "***** problem ",
            JSON.pretty_generate(problem),
            "  BUT : #{e.message}"
          ].join("\n"))
          raise e
        end
        @solution
      end

      private

      def solve(problem)
        calc = CalculatorFactory.build
        solution = nil
        @equations = {}
        begin
          problem.map do |k, v|
            if v.to_i.to_s == v || v.to_f.to_s == v
              calc.store(k => v.to_f)
            else
              equations[k] = v
            end
          end
          solution = calc.solve!(equations)
        end
        @solution = solution
      end

      def benchmark(message)
        start = Time.now
        value = nil
        begin
          value = yield
        ensure
          elapsed_time = Time.now - start
          timings[message] = elapsed_time
          RulesEngine::Log.call "#{message} #{elapsed_time}"
        end
        value
      end

      def benchmark_log
        timings.map { |k, timing| [k, timing.to_s].join(" ") }.join(", ")
      end

      def duplicate_message(duplicates, _vals)
        message = duplicates.map { |key, vals| [key, "=", "\n\t\t", vals.map(&:expression).join("\n\t\t")].join("") }
                            .join("\n")
        "Duplicates for #{message}\n"
      end
    end
  end
end
