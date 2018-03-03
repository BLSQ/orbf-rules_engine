# frozen_string_literal: true

module Orbf
  module RulesEngine
    class GraphvizProjectPrinter
      def print(project)
        calc = CalculatorFactory.build

        separators = {
          'activity' => ['[', ']'],
          'package'  => ['>', ']'],
          'zone'     => ['((', '))']
        }
        diagram = project.packages.flat_map(&:rules).flat_map(&:formulas).map do |formula|
          sep = separators[formula.rule.kind.to_s]
          raise "no separators for #{formula.rule.kind} vs #{separators}" unless sep

          dependencies = calc.dependencies(formula.expression.gsub('%{', '').gsub('_values}', ''))
          dependencies.map do |dependency|
            formula.code + '--> ' + dependency + ';'
          end + [
            "#{formula.code}#{sep.first}\"<b>#{formula.code}</b><br>#{formula.expression}\"#{sep.last};"
          ]
        end
        Orbf::RulesEngine::Log.call diagram.flatten.uniq
      end
    end
  end
end
