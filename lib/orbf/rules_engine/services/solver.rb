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
        duplicates = @variables.group_by(&:key)
                               .select { |_, vals| vals.reject { |v| v.type == "activity_constant" }.uniq.size > 1 }
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
            # JSON.pretty_generate(problem),
            "**** solution ",
            # JSON.pretty_generate(solution.map { |k, v| [k, v.to_f] }.to_h),
            " #{benchmark_log} : problem size=#{problem.size} (#{equations.size})"
          ].join("\n")
        rescue StandardError => e
          # File.open("/tmp/temp.json", "w") do |f|
          #  f.write(JSON.pretty_generate(problem))
          # end
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
        @equations = {}
        begin
          split_problem(problem, calc)
          @solution = calc.solve(equations) do |missing_var_error|
            puts [
              "WARN !" + missing_var_error.message,
              "\t recipient_variable : #{missing_var_error.recipient_variable}",
              "\t unbound_variables  : #{missing_var_error.unbound_variables}"
            ].join("\n")
            raise missing_var_error
          end
        end
        @solution
      end

      def split_problem(problem, calc)
        problem.map do |k, v|
          if [v.to_i.to_s, v.to_f.to_s].include?(v)
            calc.store(k => v.to_f)
          else
            equations[k] = v
          end
        end
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
      # rubocop:enable Rails/TimeZone

      def benchmark_log
        timings.map { |k, timing| [k, timing.to_s].join(" ") }.join(", ")
      end

      def duplicate_message(duplicates, _vals)
        message = duplicates.map { |key, vals| duplicate_key_message(key, vals) }
                            .join("\n")
        "Duplicates for #{message}\n"
      end

      def duplicate_key_message(key, vals)
        [
          key,
          "=",
          "\n\t\t",
          vals.map(&:expression).join("\n\t\t"),
          "  " + vals.size.to_s
        ].join("")
      end
    end
  end
end
