# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Dhis2ValuesPrinter
      attr_reader :variables, :solution

      def initialize(variables, solution)
        @variables = variables
        @solution = solution
      end

      def print
        variables.select(&:exportable?)
                 .map do |variable|
          {
            dataElement: variable.dhis2_data_element,
            orgUnit:     variable.orgunit_ext_id,
            period:      variable.period,
            value:       ValueFormatter.format(solution[variable.key]),
            comment:     variable.key
          }
        end
      end
    end
  end
end
