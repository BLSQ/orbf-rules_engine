module Orbf
  module RulesEngine
    class FetchData
      def initialize(dhis2_connection, package_arguments)
        @package_arguments = package_arguments
        @dhis2_connection = dhis2_connection
      end

      def call
        values = dhis2_connection.data_value_sets.list(
          organisation_unit: orgunit_ext_ids,
          data_sets:         dataset_ext_ids,
          periods:           periods,
          children:          false
        )

        results = values.data_values || []

        map_to_raw(results)
      end

      private

      attr_reader :dhis2_connection, :package_arguments

      def orgunit_ext_ids
        package_arguments.flat_map(&:orgunits).flat_map(&:parent_ext_ids).uniq
      end

      def dataset_ext_ids
        package_arguments.flat_map(&:datasets_ext_ids).uniq
      end

      def periods
        package_arguments.flat_map(&:periods).uniq
      end

      def map_to_raw(results)
        results.map do |v|
          {
            "dataElement"          => v["data_element"],
            "period"               => v["period"],
            "orgUnit"              => v["org_unit"],
            "categoryOptionCombo"  => v["category_option_combo"],
            "attributeOptionCombo" => v["attribute_option_combo"],
            "value"                => v["value"],
            "storedBy"             => v["stored_by"],
            "created"              => v["created"],
            "lastUpdated"          => v["last_updated"],
            "followUp"             => v["follow_up"]
          }
        end
      end
    end
  end
end
