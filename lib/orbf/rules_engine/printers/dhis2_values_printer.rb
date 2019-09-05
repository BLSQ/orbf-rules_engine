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
          value = ValueFormatter.format(variable.exportable_value(solution))

          add_coc_and_aoc(variable,
                          dataElement: variable.dhis2_data_element,
                          orgUnit:     variable.orgunit_ext_id,
                          period:      variable.dhis2_period,
                          value:       value,
                          comment:     variable.key)
        end

        uniq_values(values)
      end

      def add_coc_and_aoc(variable, value)
        value[:categoryOptionCombo] ||= variable.category_option_combo_ext_id if variable.category_option_combo_ext_id.present?
        value[:categoryOptionCombo] ||= default_category_option_combo_ext_id if default_category_option_combo_ext_id.present?
        value[:attributeOptionCombo] ||= default_attribute_option_combo_ext_id if default_attribute_option_combo_ext_id.present?
        value
      end

      def uniq_values(values)
        values.uniq do |value|
          [value[:dataElement],
           value[:orgUnit],
           value[:period],
           value[:categoryOptionCombo],
           value[:value]]
        end
      end
    end
  end
end
