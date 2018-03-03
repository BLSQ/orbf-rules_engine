
# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Solver
      attr_reader :variables, :solution

      def initialize
        @variables = []
      end

      def register_variables(vars)
        @variables.push(*vars)
        duplicates = @variables.group_by(&:key).select { |_key, vals| vals.size > 1 }

        raise "Duplicates for \n#{duplicates.map { |key, vals| [key, '=', "\n\t\t", vals.map(&:expression).join("\n\t\t")].join('') }.join("\n")}" if duplicates.any?
      end

      def build_problem
        variables.map { |variable| [variable.key, variable.expression] }.to_h
      end

      def solve!
        start = Time.now
        stop = nil
        problem = build_problem
        build_time = Time.now - start
        calc = CalculatorFactory.build
        solution = nil
        equations = {}
        begin
          # StackProf.run(mode: :cpu, out: "tmp/stackprof-cpu-myapp.dump") do

          problem.map do |k, v|
            if v.to_i.to_s == v || v.to_f.to_s == v
              calc.store(k => v.to_f)
            else
              equations[k] = v
            end
          end

          solution = calc.solve!(equations)
        # end
        ensure
          stop = Time.now
        end
        solution_time = stop - start
        RulesEngine::Log.call "***** problem #{solution_time}"
        RulesEngine::Log.call JSON.pretty_generate(problem)
        RulesEngine::Log.call "**** solution #{Time.now}"

        RulesEngine::Log.call JSON.pretty_generate(solution.map { |k, v| [k, v.to_f] }.to_h)

        RulesEngine::Log.call " solved in #{solution_time}, built in #{build_time} : problem size=#{problem.size} (#{equations.size})"
        @solution = solution
      rescue StandardError => e
        RulesEngine::Log.call "***** problem #{stop - start}"
        RulesEngine::Log.call JSON.pretty_generate(problem)
        RulesEngine::Log.call "  BUT : #{e.message}"
        raise e
      end
    end
  end
end
