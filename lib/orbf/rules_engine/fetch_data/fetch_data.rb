module Orbf
  module RulesEngine
    class FetchData
      def initialize(dhis2_connection, package_arguments)
        @package_arguments = package_arguments
        @dhis2_connection = dhis2_connection
      end

      def call
        orgunit_ext_ids = package_arguments.flat_map(&:orgunits).flat_map(&:parent_ext_ids).uniq
        dataset_ext_ids = package_arguments.flat_map(&:datasets_ext_ids).uniq
        periods = package_arguments.flat_map(&:periods).uniq
        values = dhis2_connection.data_value_sets.list(
          {
            org_unit: orgunit_ext_ids,
            data_set: dataset_ext_ids,
            period:   periods,
            children: false
          }, true
        )

        values || []
      end

      private

      attr_reader :dhis2_connection, :package_arguments
    end
  end
end
