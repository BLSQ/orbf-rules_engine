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
        values = variables.select(&:exportable?)
                          .map do |variable|
          {
            dataElement: variable.dhis2_data_element,
            orgUnit:     variable.orgunit_ext_id,
            period:      format_period(variable),
            value:       ValueFormatter.format(solution[variable.key]),
            comment:     variable.key
          }
        end
        uniq_values(values)
      end

      def uniq_values(values)
        values.uniq do |value|
          [value[:dataElement],
           value[:orgUnit],
           value[:period],
           value[:value]]
        end
    end

      def format_period(variable)
        return variable.period unless variable.formula.frequency
        Orbf::RulesEngine::PeriodIterator.periods(
          variable.period,
          variable.formula.frequency
        ).last
      end
    end
  end
end
