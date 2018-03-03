# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Dhis2IndexedValues
      def initialize(dhis2_values)
        @indexed_values = index_by(dhis2_values, %w[dataElement period orgUnit categoryOptionCombo])
        @indexed_values_without_category = index_by(dhis2_values, %w[dataElement period orgUnit])
      end

      def lookup_values(period, orgunit, data_element, category_option_combo)
        values = if category_option_combo
                   @indexed_values[[data_element, period, orgunit, category_option_combo]]
                 else
                   @indexed_values_without_category[[data_element, period, orgunit]]
                 end
        values || []
      end

      def index_by(dhis2_values, attribute_names)
        dhis2_values.group_by do |value|
          attribute_names.map { |attribute_name| value[attribute_name] }
        end
      end
    end
  end
end
