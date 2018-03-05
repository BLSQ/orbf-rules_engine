# frozen_string_literal: true

module Orbf
  module RulesEngine
    class DecisionVariablesBuilder
      def initialize(package, orgunits, period)
        @package = package
        @orgunits = if package.subcontract?
                      orgunits[0..0]
                    else
                      orgunits
                    end
        @period = period
      end

      def to_variables
        []
      end
    end
  end
end
