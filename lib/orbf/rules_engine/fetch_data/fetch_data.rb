module Orbf
  module RulesEngine
    class FetchData
      def initialize(dhis2_connection, package_arguments)
        @package_arguments = package_arguments
        @dhis2_connection = dhis2_connection
      end

      # TODO SMS ask piet ;)
      #    - what to do it data is coming from data values sets to
      #       - drop the one from analytics, need to find "duplicates" ?
      def call
        data_value_sets_values + analytics_values
      end

      private

      attr_reader :dhis2_connection, :package_arguments

      def data_value_sets_values
        Orbf::RulesEngine::FetchDataValueSets.new(dhis2_connection, package_arguments).call
      end

      def analytics_values
        Orbf::RulesEngine::FetchDataAnalytics.new(dhis2_connection, package_arguments).call
      end
    end
  end
end
