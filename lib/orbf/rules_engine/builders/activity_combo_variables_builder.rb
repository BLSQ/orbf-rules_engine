# frozen_string_literal: true

module Orbf
  module RulesEngine
    class ActivityComboVariablesBuilder
      include VariablesBuilderSupport

      def initialize(package, orgunits, lookup)
        @package = package
        @orgunits = orgunits
        @lookup = lookup
      end

      attr_reader :package, :orgunits

      def self.to_variables(package_arguments, dhis2_values)
        lookup = dhis2_values
                 .group_by do |v|
          [
            v["orgUnit"] || v[:orgUnit],
            v["period"] || v[:period],
            v["dataElement"] || v[:dataElement],
            v["categoryOptionCombo"] || v[:categoryOptionCombo]
          ]
        end

        package_arguments.values.each_with_object([]) do |package_argument, package_vars|
          next unless package_argument.package.loop_over_combo

          package_argument.periods.each do |period|
            package_vars.push(*RulesEngine::ActivityComboVariablesBuilder.new(
              package_argument.package,
              package_argument.orgunits,
              lookup
            ).convert(period))
          end
        end
      end

      def convert(period)
        orgunits.each_with_object([]) do |orgunit, array|
          package.all_activities_codes.each do |activity_code|
            activity = package.activities.detect { |candidate| candidate.activity_code == activity_code }
            activity.activity_states.each do |activity_state|
              package.loop_over_combo[:category_option_combos].each do |category_option_combo|
                value = @lookup[[orgunit.ext_id, period, activity_state.ext_id, category_option_combo[:id]]]
                value = (value.first[:value] || value.first["value"]) if value && value.first

                key = suffix_for_id_activity(package.code, activity_code + "_" + category_option_combo[:id], activity_state.state, orgunit.ext_id, period)
                array.push(
                  Orbf::RulesEngine::Variable.new_activity(
                    period:         period,
                    key:            key,
                    expression:     value || "0",
                    state:          activity_state.state,
                    activity_code:  activity_code,
                    orgunit_ext_id: orgunit.ext_id,
                    formula:        nil,
                    package:        package
                  )
                )

                key = suffix_for_id_activity(package.code, activity_code + "_" + category_option_combo[:id], activity_state.state + "_is_null", orgunit.ext_id, period)
                array.push(
                  Orbf::RulesEngine::Variable.new_activity(
                    period:         period,
                    key:            key,
                    expression:     value ? "0" : "1",
                    state:          activity_state.state+"_is_null",
                    activity_code:  activity_code,
                    orgunit_ext_id: orgunit.ext_id,
                    formula:        nil,
                    package:        package
                  )
                )
              end
            end
          end
        end
      end
    end
  end
end
