# frozen_string_literal: true

module Orbf
  module RulesEngine
    class ActivityVariablesBuilder
      include VariablesBuilderSupport

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
          package.activities.each do |activity|
            activity.activity_states.select(&:data_element?).each do |activity_state|
              SOURCES.each do |source|
                send(source, activity_state, period, package.activity_dependencies) do |orgunit_id, state, expression|
                  state = suffix_raw(state) if package.subcontract?
                  array.push Orbf::RulesEngine::Variable.with(
                    period:         period,
                    key:            suffix_for_id_activity(package.code, activity.activity_code, state, orgunit_id, period),
                    expression:     expression,
                    state:          state,
                    activity_code:  activity.activity_code,
                    type:           Orbf::RulesEngine::Variable::Types::ACTIVITY,
                    orgunit_ext_id: orgunit_id,
                    formula:        nil,
                    package:        package
                  )
                end
              end
            end
          end
        end
      end

      private

      attr_reader :package, :orgunits, :lookup

      SOURCES = %i[de_values parent_values].freeze

      def de_values(activity_state, period, _dependencies)
        orgunits.each do |orgunit|
          key = [orgunit.ext_id, period, activity_state.ext_id]
          current_value = lookup[key]
          var = current_value ? current_value.first["value"] : 0
          yield(orgunit.ext_id, activity_state.state, var)
        end
      end

      def parent_values(activity_state, period, dependencies)
        parents_with_level.each do |hash|
          code = "#{activity_state.state}_level#{hash[:level]}"
          next unless dependencies.include?(code)
          key = [hash[:id], period, activity_state.ext_id]
          hash_value = lookup[key] ? lookup[key].first["value"].to_s : "0"

          yield(hash[:id], code, hash_value)
        end
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
    end
  end
end
