module Orbf
module RulesEngine
  class GraphvizVariablesPrinter
    def print(variables)
      calc = CalculatorFactory.build

      diagram = variables.flat_map do |variable|
        dependencies = calc.dependencies(variable.expression)
        dependencies.map do |dependency|
          variable.key + "--> " + dependency + ";"
        end
      end
      Orbf::RulesEngine::Log.call diagram.uniq
    end
  end
end
end