module Orbf
module RulesEngine
  class GraphvizVariablesPrinter
    def print(variables)
      diagram = variables.flat_map do |variable|
        dependencies = CalculatorFactory.dependencies(variable.expression)
        dependencies.map do |dependency|
          variable.key + "--> " + dependency + ";"
        end
      end
      Orbf::RulesEngine::Log.call diagram.uniq
    end
  end
end
end