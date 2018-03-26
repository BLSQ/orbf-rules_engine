# frozen_string_literal: true

module Orbf
  module RulesEngine
    class GraphvizProjectPrinter

      def print_project(project)
        print_packages(project.packages)
      end

      def print_packages(packages)
        calc = CalculatorFactory.build

        separators = {
          "entities_aggregation" => ["[", "]"],
          "activity" => ["[", "]"],
          "package"  => [">", "]"],
          "zone"     => ["((", "))"]
        }
        diagrams =[]
        packages.each do |package|
          diagram = package.rules.flat_map(&:formulas).map do |formula|
            sep = separators[formula.rule.kind.to_s]
            raise "no separators for #{formula.rule.kind} vs #{separators}" unless sep

            dependencies = calc.dependencies(formula.expression.gsub("%{", "").gsub("_values}", ""))
            dependencies.map do |dependency|
              formula.code + "--> " + dependency + ";"
            end + [
               "#{formula.code}#{sep.first}\"<b>#{formula.code}</b>\"#{sep.last};"
             ]
          end
          diagrams.push diagram.flatten.uniq.join("\n")
        end

        Orbf::RulesEngine::Log.call diagrams
        diagrams
      end
    end
  end
end
