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
          activity.activity_states.each do |activity_state|
            array.push(build_variable(activity, activity_state))
          end
        end
      end

      private

      attr_reader :package, :orgunits, :ref_orgunit, :period

      def build_variable(activity, activity_state)
        Orbf::RulesEngine::Variable.with(
          period:         period,
          key:            build_key(package, activity, activity_state, period),
          expression:     "SUM(#{org_units_expression(package, activity, activity_state, period).join(', ')})",
          state:          activity_state.state.to_s,
          activity_code:  activity.activity_code,
          type:           "contract",
          orgunit_ext_id: ref_orgunit.ext_id,
          formula:        nil,
          package:        package
        )
      end

      # achieved_for_2_and_2016, achieved_for_4_and_2016
      def org_units_expression(package, activity, activity_state, period)
        orgunits.each_with_object([]) do |orgunit, array|
          next unless SumIf.sum_if(package, activity, orgunit)
          array.push suffix_for_activity(
            package.code,
            activity.activity_code,
            suffix_raw(activity_state.state),
            orgunit,
            period
          )
        end
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
