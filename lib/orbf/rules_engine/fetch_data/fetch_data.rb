module Orbf
  module RulesEngine
    class FetchData
      def initialize(dhis2_connection:, package_arguments:, read_through_deg:)
        @package_arguments = package_arguments
        @dhis2_connection = dhis2_connection
        @read_through_deg = read_through_deg
      end

      def call
        data_value_sets_values + analytics_values
      end

      private

      attr_reader :dhis2_connection, :package_arguments, :read_through_deg

      def data_value_sets_values
        Orbf::RulesEngine::FetchDataValueSets.new(
          dhis2_connection:  dhis2_connection,
          package_arguments: package_arguments,
          read_through_deg:  read_through_deg
        ).call
      end

      def analytics_values
        Orbf::RulesEngine::FetchDataAnalytics.new(dhis2_connection, package_arguments).call
      end
    end
  end
end
