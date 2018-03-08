# frozen_string_literal: true

module Orbf
  module RulesEngine
    class ContractVariablesBuilder
      include VariablesBuilderSupport

      def initialize(package, orgunits, period)
        @package = package
        @ref_orgunit = orgunits[0]
        @orgunits = orgunits
        @period = period
      end

      def to_variables
        return [] unless package.subcontract?
        package.activities.each_with_object([]) do |activity, array|
          filtered_orgunits = SumIf.org_units(orgunits, package, activity)
          activity.activity_states.each do |activity_state|
            array.push(build_variable(filtered_orgunits, activity, activity_state))
          end
          array.push(build_count("org_units_count", orgunits.size, activity))
          array.push(build_count("org_units_sum_if_count", filtered_orgunits.size, activity))
        end
      end

      private

      attr_reader :package, :orgunits, :ref_orgunit, :period

      def build_variable(filtered_orgunits, activity, activity_state)
        expressions = org_units_expression(filtered_orgunits, activity, activity_state, period)

        Orbf::RulesEngine::Variable.with(
          period:         period,
          key:            build_key(package, activity, activity_state, period),
          expression:     "SUM(#{expressions.join(', ')})",
          state:          activity_state.state.to_s,
          activity_code:  activity.activity_code,
          type:           "contract",
          orgunit_ext_id: ref_orgunit.ext_id,
          formula:        nil,
          package:        package
        )
      end

      # achieved_for_2_and_2016, achieved_for_4_and_2016
      def org_units_expression(filtered_orgunits, activity, activity_state, period)
        filtered_orgunits.each_with_object([]) do |orgunit, array|
          array.push suffix_for_activity(
            package.code, activity.activity_code,
            suffix_raw(activity_state.state),
            orgunit, period
          )
        end
      end

      def build_count(count_code, count, activity)
        Orbf::RulesEngine::Variable.with(
          period:         period,
          key:            suffix_for_id(
            [package.code, activity.activity_code, count_code].join("_"),
            ref_orgunit.ext_id,
            period
          ),
          expression:     count.to_s,
          state:          count_code.to_s,
          activity_code:  activity.activity_code,
          type:           "contract",
          orgunit_ext_id: ref_orgunit.ext_id,
          formula:        nil,
          package:        package
        )
      end

      def build_key(package, activity, activity_state, period)
        suffix_for_id(
          [package.code, activity.activity_code, activity_state.state].join("_"),
          ref_orgunit.ext_id,
          period
        )
      end
    end
  end
end
