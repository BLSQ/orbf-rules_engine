module Orbf
  module RulesEngine
    class FetchData
      def initialize(dhis2_connection, package_arguments)
        @package_arguments = package_arguments
        @dhis2_connection = dhis2_connection
      end

      def call
        results = []
        if dataset_ext_ids.any?
          orgunit_ext_ids.each_slice(50).each do |orgunit_slice|
            values = dhis2_connection.data_value_sets.list(
              organisation_unit: orgunit_slice,
              data_sets:         dataset_ext_ids,
              periods:           periods,
              children:          false
            )

            results.push(*(values.data_values || []))
          end
        end

        data_values_results = map_to_raw(results)

        analytics_activity_states = package_arguments.flat_map do |pa|
          pa.package.activities.flat_map(&:activity_states).select(&:origin_analytics?)
        end

        return data_values_results if analytics_activity_states.none?

        # TODO: SMS ask piet ;)
        #    - handle too long urls ?
        #    - what to do it data is coming from data values sets too ?
        #       - drop the one from analytics, need to find "duplicates" ?

        without_parents_ext_ids = package_arguments.flat_map(&:orgunits).flat_map(&:to_a).map(&:ext_id).uniq.join(";")
        without_yearly_periods = package_arguments.map(&:periods).map { |p| p[0..-3] }.uniq.flatten.join(";")
        analytics_values = { "rows" => [] }

        analytics_values = dhis2_connection.analytics.list(
          periods:            without_yearly_periods,
          organisation_units: without_parents_ext_ids,
          data_elements:      analytics_activity_states.map(&:ext_id).join(";").gsub("inlined-", "")
        )

        # ugly hack for dataelement.category_combo_combo
        mappings = analytics_activity_states.each_with_object({}) do |activity_state, acc|
          next unless activity_state.ext_id.start_with?("inlined-")

          acc[activity_state.ext_id.gsub("inlined-", "")] = activity_state.ext_id
        end

        analytics_results = analytics_values["rows"].map do |v|
          {
            "dataElement"          => mappings[v[0]] || v[0],
            "period"               => v[2],
            "orgUnit"              => v[1],
            "categoryOptionCombo"  => "default",
            "attributeOptionCombo" => "default",
            "value"                => v[3]
          }
        end

        data_values_results + analytics_results
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
            "followUp"             => v["follow_up"]
          }
        end
      end
    end
  end
end
