module Orbf
  module RulesEngine
    class FetchDataAnalytics
      def initialize(dhis2_connection, package_arguments)
        @package_arguments = package_arguments
        @dhis2_connection = dhis2_connection
      end

      # TODO: SMS ask piet ;)
      #    - handle too long urls ?
      def call
        return [] if analytics_activity_states.none?

        analytics_values = dhis2_connection.analytics.list(
          periods:            without_yearly_periods,
          organisation_units: orgunit_ext_ids,
          data_elements:      data_elements
        )
        map_to_data_values(analytics_values)
      end

      private

      INLINED_PREFIX = "inlined-".freeze

      attr_reader :dhis2_connection, :package_arguments

      def map_to_data_values(analytics_values)
        analytics_values["rows"].map do |v|
          {
            "dataElement"          => data_element_mappings[v[0]] || v[0],
            "period"               => v[2],
            "orgUnit"              => v[1],
            "categoryOptionCombo"  => "default",
            "attributeOptionCombo" => "default",
            "value"                => v[3]
          }
        end
      end

      # ugly hack for dataelement.category_combo_combo
      def data_element_mappings
        @data_element_mappings ||= analytics_activity_states.each_with_object({}) do |activity_state, acc|
          next if activity_state.ext_id.nil? # badly configured constant with origin=analytics
          next unless activity_state.ext_id.start_with?(INLINED_PREFIX) # data_element.category_option_combo

          acc[activity_state.ext_id.gsub(INLINED_PREFIX, "")] = activity_state.ext_id
        end
      end

      def analytics_activity_states
        @analytics_activity_states ||= package_arguments.flat_map do |pa|
          pa.package.activities.flat_map(&:activity_states).select(&:origin_analytics?)
        end
      end

      def data_elements
        analytics_activity_states.map(&:ext_id).uniq.join(";").gsub(INLINED_PREFIX, "")
      end

      def orgunit_ext_ids
        @orgunit_ext_ids ||= package_arguments.flat_map(&:orgunits).flat_map(&:to_a).map(&:ext_id).uniq.join(";")
      end

      def without_yearly_periods
        package_arguments.map(&:periods).map { |p| p[0..-3] }.uniq.flatten.join(";")
      end
    end
  end
end
