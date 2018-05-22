# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Dhis2ValuesPrinter
      attr_reader :variables, :solution, :default_category_option_combo_ext_id, :default_attribute_option_combo_ext_id

      def initialize(variables, solution, default_category_option_combo_ext_id: nil, default_attribute_option_combo_ext_id: nil)
        @variables = variables
        @solution = solution
        @default_category_option_combo_ext_id = default_category_option_combo_ext_id
        @default_attribute_option_combo_ext_id = default_attribute_option_combo_ext_id
      end

      def print
        values = variables.select(&:exportable?)
                          .map do |variable|
          add_coc_and_aoc(
            dataElement: variable.dhis2_data_element,
            orgUnit:     variable.orgunit_ext_id,
            period:      format_period(variable),
            value:       ValueFormatter.format(solution[variable.key]),
            comment:     variable.key
          )
        end
        uniq_values(values)
      end

      def add_coc_and_aoc(value)
        value[:categoryOptionCombo] = default_category_option_combo_ext_id unless default_category_option_combo_ext_id.blank?
        value[:attributeOptionCombo] = default_attribute_option_combo_ext_id unless default_attribute_option_combo_ext_id.blank?
        value
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
