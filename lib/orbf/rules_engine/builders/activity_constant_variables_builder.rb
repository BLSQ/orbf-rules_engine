# frozen_string_literal: true

module Orbf
  module RulesEngine
    class ActivityConstantVariablesBuilder
      include VariablesBuilderSupport

      def initialize(package, orgunits, period)
        @package = package
        @orgunits = orgunits
        @period = period
      end

      def to_variables
        activity_constant_variables.uniq
      end

      private

      attr_reader :package, :orgunits, :period

      def activity_constant_variables
        package.activities.each_with_object([]) do |activity, array|
          activity.activity_states.select(&:constant?).each do |activity_state|
            array.push new_var(activity, activity_state)
          end
        end
      end

      def new_var(activity, activity_state)
        Orbf::RulesEngine::Variable.new_activity_constant(
          period:        period,
          key:           name_constant(activity.activity_code, activity_state.state, period),
          expression:    activity_state.formula,
          state:         activity_state.state,
          activity_code: activity.activity_code,
          package:       package
        )
      end
    end
  end
end
