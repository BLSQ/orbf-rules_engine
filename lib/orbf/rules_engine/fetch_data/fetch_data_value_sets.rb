module Orbf
  module RulesEngine
    class FetchDataValueSets
      def initialize(dhis2_connection:, package_arguments:, read_through_deg:)
        @package_arguments = package_arguments
        @dhis2_connection = dhis2_connection
        @read_through_deg = read_through_deg
      end

      def call
        return [] if dataset_ext_ids.none? && deg_ext_ids.none?

        results = []

        orgunit_ext_ids.each_slice(50).each do |orgunit_slice|
          values = fetch_data_value_sets(orgunit_slice)

          results.push(*(values.data_values || []))
        end

        map_to_raw(results)
      end

      private

      attr_reader :dhis2_connection, :package_arguments, :read_through_deg

      def fetch_data_value_sets(orgunit_slice)
        if read_through_deg
          dhis2_connection.data_value_sets.list(
            organisation_unit:   orgunit_slice,
            data_element_groups: deg_ext_ids,
            periods:             periods,
            children:            false
          )
        else
          dhis2_connection.data_value_sets.list(
            organisation_unit: orgunit_slice,
            data_sets:         dataset_ext_ids,
            periods:           periods,
            children:          false
          )
        end
      end

      def orgunit_ext_ids
        package_arguments.flat_map(&:orgunits)
                         .flat_map(&:to_a)
                         .flat_map(&:parent_ext_ids)
                         .uniq
                         .sort
      end

      def deg_ext_ids
        @deg_ext_ids ||= package_arguments.map(&:package).map(&:deg_ext_id).uniq.compact.sort
      end

      def dataset_ext_ids
        @dataset_ext_ids ||= package_arguments.flat_map(&:datasets_ext_ids).uniq.compact.sort
      end

      def periods
        @periods ||= package_arguments.flat_map(&:periods).uniq.sort
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
