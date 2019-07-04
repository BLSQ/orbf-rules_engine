# frozen_string_literal: true

module Orbf
  module RulesEngine
    class ActivityVariablesBuilder
      include VariablesBuilderSupport

      class ValueLookup < Orbf::RulesEngine::ValueObject
        attributes :value, :is_null

        attr_reader :value, :is_null

        def initialize(value:, is_null:)
          @value = value
          @is_null = is_null
          freeze
        end
      end

      class << self
        def to_variables(package_arguments, dhis2_values)
          package_arguments.values.each_with_object([]) do |package_argument, package_vars|
            package_argument.periods.each do |period|
              package_vars.push(*RulesEngine::ActivityVariablesBuilder.new(
                package_argument.package,
                package_argument.orgunits,
                dhis2_values
              ).convert(period))
            end
          end
        end
      end

      def initialize(package, orgunits, dhis2_values)
        @package = package
        @orgunits = orgunits
        @lookup = dhis2_values
                  .group_by { |v| [v["orgUnit"], v["period"], v["dataElement"]] }
      end

      def convert(period)
        [package].each_with_object([]) do |package, array|
          dependencies = package.activity_dependencies
          flattened_dependencies = dependencies.to_a.join(",")
          package.activities.each do |activity|
            package.harmonized_activity_states(activity).reject(&:constant?).each do |activity_state|
              SOURCES.each do |source|
                send(source, activity_state, period, dependencies) do |orgunit_id, state, expression|
                  suffixed_state = package.subcontract? ? suffix_raw(state) : state
                  express = expression.value
                  array.push register_vars(package, activity.activity_code, suffixed_state, express, orgunit_id, period)

                  if using_is_null?(flattened_dependencies, state)
                    express = expression.is_null ? "1" : "0"
                    array.push register_vars(package, activity.activity_code, suffix_is_null(suffixed_state), express, orgunit_id, period)
                  end
                end
              end
            end
          end
        end
      end

      private

      def using_is_null?(flattened_dependencies, state)
        flattened_dependencies.include?(suffix_is_null(state))
      end

      attr_reader :package, :orgunits, :lookup

      SOURCES = %i[de_values parent_values main_orgunit_values].freeze

      def register_vars(package, activity_code, state, expression, orgunit_id, period)
        Orbf::RulesEngine::Variable.new_activity(
          period:         period,
          key:            suffix_for_id_activity(package.code, activity_code, state, orgunit_id, period),
          expression:     expression,
          state:          state,
          activity_code:  activity_code,
          orgunit_ext_id: orgunit_id,
          formula:        nil,
          package:        package
        )
      end

      def de_values(activity_state, period, _dependencies)
        orgunits.each do |orgunit|
          current_value = lookup_value(build_keys_with_yearly([orgunit.ext_id, period, activity_state.ext_id]), activity_state)
          yield(orgunit.ext_id, activity_state.state, current_value)
        end
      end

      def parent_values(activity_state, period, dependencies)
        parents_with_level.each do |hash|
          codes = [
            "#{activity_state.state}_level_#{hash[:level]}",
            "#{activity_state.state}_level_#{hash[:level]}_quarterly"
          ]
          codes.each do |code|
            next unless dependencies.include?(code)

            keys = if code.end_with?("_quarterly")
                     quarter = PeriodIterator.periods(period, "quarterly").first
                     [[hash[:id], quarter, activity_state.ext_id]]
                   else
                     build_keys_with_yearly([hash[:id], period, activity_state.ext_id])
                   end
            hash_value = lookup_value(keys, activity_state)
            yield(hash[:id], code, hash_value)
          end
        end
      end

      def main_orgunit_values(activity_state, period, dependencies)
        code = "#{activity_state.state}_zone_main_orgunit"
        return unless dependencies.include?(code)

        main_orgunit_ext_id = orgunits.first.ext_id
        key = [main_orgunit_ext_id, period, activity_state.ext_id]
        hash_value = lookup_value(build_keys_with_yearly(key), activity_state)
        yield(main_orgunit_ext_id, code, hash_value)
      end

      def parents_with_level
        @parents_with_level ||= orgunits.each_with_object([]) do |orgunit, array|
          orgunit.parent_ext_ids.each_with_index do |id, index|
            array.push(
              id:    id,
              level: index + 1
            )
          end
        end.uniq
      end

      def lookup_value(keys, activity_state)
        keys.each do |key|
          vals = if key.first.is_a?(Array)
                   v = key.map { |k| lookup[k] }.compact
                   v.empty? ? nil : v.flatten(1)
                 else
                   lookup[key]
                 end

          next unless vals

          looked_vals = vals.map { |val| val["value"] }.compact

          next if looked_vals.empty?

          if looked_vals.size == 1
            # preserved type of original value (avoid to string)
            return ValueLookup.new(value: looked_vals.first, is_null: false)
          end

          looked_vals = if activity_state.origin_data_value_sets?
                          vals.reject { |val| val["origin"] == "analytics" || val["value"].nil? }
                        else
                          vals.reject { |val| val["origin"] != "analytics" || val["value"].nil? }
                        end

          return ValueLookup.new(value: looked_vals.map { |val| val["value"] }.join(" + "), is_null: false)
        end
        ValueLookup.new(value: "0", is_null: true)
      end

      def build_keys_with_yearly(key)
        orgunit = key[0]
        period = key[1]
        de = key[2]

        keys = [
          key,
          [orgunit, PeriodIterator.periods(period, "yearly").first, de],
          [orgunit, PeriodIterator.periods(period, "financial_july").first, de]
        ]

        if period.include?("Q")
          keys << PeriodIterator.periods(period, "monthly").map { |pe| [orgunit, pe, de] }
        end

        keys
      end
    end
  end
end
