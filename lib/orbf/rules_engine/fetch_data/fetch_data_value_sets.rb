module Orbf
  module RulesEngine
    class FetchDataValueSets
      def initialize(dhis2_connection, package_arguments)
        @package_arguments = package_arguments
        @dhis2_connection = dhis2_connection
      end

      def call
        return [] if dataset_ext_ids.none?

        results = []

        orgunit_ext_ids.each_slice(50).each do |orgunit_slice|
          values = dhis2_connection.data_value_sets.list(
            organisation_unit: orgunit_slice,
            data_sets:         dataset_ext_ids,
            periods:           periods,
            children:          false
          )

          results.push(*(values.data_values || []))
        end

        map_to_raw(results)
      end

      private

      attr_reader :dhis2_connection, :package_arguments

      def orgunit_ext_ids
        package_arguments.flat_map(&:orgunits)
                         .flat_map(&:to_a)
                         .flat_map(&:parent_ext_ids)
                         .uniq
                         .sort
      end

      def dataset_ext_ids
        package_arguments.flat_map(&:datasets_ext_ids).uniq.sort
      end

      def periods
        package_arguments.flat_map(&:periods).uniq.sort
      end

      def map_to_raw(results)
        results.each_with_object([]) do |v, cleaned|
          next if v["value"].nil?

          cleaned << {
            "dataElement"          => v["data_element"],
            "period"               => v["period"],
            "orgUnit"              => v["org_unit"],
            "categoryOptionCombo"  => v["category_option_combo"],
            "attributeOptionCombo" => v["attribute_option_combo"],
            "value"                => v["value"],
            "storedBy"             => v["stored_by"],
            "created"              => v["created"],
            "lastUpdated"          => v["last_updated"],
            "followUp"             => v["follow_up"],
            "origin"               => "dataValueSets"
          }
        end
      end
    end
  end
end
