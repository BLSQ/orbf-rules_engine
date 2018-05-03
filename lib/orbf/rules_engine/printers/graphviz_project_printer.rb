# frozen_string_literal: true

module Orbf
  module RulesEngine
    class GraphvizProjectPrinter
      SEPERATORS = {
        "entities_aggregation" => ["[", "]"],
        "activity"             => ["[", "]"],
        "package"              => [">", "]"],
        "zone"                 => ["(", ")"]
      }.freeze
      STYLES = {
        "entities_aggregation" => "fill:#d6cbd3",
        "activity"             => "fill:#eca1a6",
        "package"              => "fill:#bdcebe",
        "zone"                 => "fill:#ada397"
      }.freeze

      TODO_ADDITIONAL_STYLE = ",stroke:#FF9900,stroke-width:8px,stroke-dasharray: 8, 8;"

      def print_project(project)
        print_packages(project.packages)
      end

      def print_packages(packages)
        calc = CalculatorFactory.build

        diagrams = []
        packages.each do |package|
          diagram = package.rules.flat_map(&:formulas).map do |formula|
            sep = SEPERATORS[formula.rule.kind.to_s]
            raise "no separators for #{formula.rule.kind} vs #{separators}" unless sep

            dependencies = calc.dependencies(formula.expression.gsub("%{", "").gsub("_values}", ""))
            dig = dependencies.map do |dependency|
              formula.code + "--> " + dependency + ";"
            end

            dig + node_formula(formula, sep)
          end
          diagram += package.states.map { |state| node_state(state) }
          diagrams.push diagram.flatten.uniq.join("\n")
        end

        Orbf::RulesEngine::Log.call diagrams
        diagrams
      end

      def node_formula(formula, sep)
        [
          "#{formula.code}#{sep.first}\"#{title(formula.code)}\"#{sep.last};",
          "style " + formula.code + " " + STYLES[formula.rule.kind.to_s] + additional_style(formula),
          "click " + formula.code + " \"/##{formula.code}\" \"#{tooltip(formula)}\""
        ]
      end

      def node_state(state)
        "#{state}(\"#{title(state)}\")"
      end

      def title(name)
        "<h3><b>#{name}</b></h3>"
      end

      def tooltip(formula)
        "<b>#{formula.code}</b> <br><br>" \
          "Expression: <br><code>#{formula.expression}</code><br><br>" \
          "Description: <br>#{formula.comment}"
      end

      def additional_style(formula)
        return "" unless formula.comment
        formula.comment.include?("TODO") ? TODO_ADDITIONAL_STYLE : ""
      end
    end
  end
end
