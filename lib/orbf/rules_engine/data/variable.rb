# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Variable < Orbf::RulesEngine::ValueObject
      class << self
        def new_activity_decision_table(params)
          Variable.with(
            params.merge!(
              type:         Orbf::RulesEngine::Variable::Types::ACTIVITY_RULE_DECISION,
              formula:      nil,
              payment_rule: nil
            )
          )
        end

        def new_package_decision_table(params)
          Variable.with(
            params.merge!(
              type:          Orbf::RulesEngine::Variable::Types::PACKAGE_RULE_DECISION,
              formula:       nil,
              payment_rule:  nil,
              activity_code: nil
            )
          )
        end

        def new_activity_constant(params)
          Variable.with(
            params.merge!(
              type:           Orbf::RulesEngine::Variable::Types::ACTIVITY_CONSTANT,
              formula:        nil,
              payment_rule:   nil,
              orgunit_ext_id: nil
            )
          )
        end

        def new_payment(params)
          Variable.with(
            params.merge!(
              type:          Orbf::RulesEngine::Variable::Types::PAYMENT_RULE,
              activity_code: nil,
              formula:       nil,
              package:       nil,
              payment_rule:  nil
            )
          )
        end

        def new_contract(params)
          Variable.with(
            params.merge!(
              type:         Orbf::RulesEngine::Variable::Types::CONTRACT,
              formula:      nil,
              payment_rule: nil
            )
          )
        end

        def new_package_rule(params)
          Variable.with(
            params.merge!(
              type:          Orbf::RulesEngine::Variable::Types::PACKAGE_RULE,
              activity_code: nil,
              payment_rule:  nil
            )
          )
        end

        def new_activity_rule(params)
          Variable.with(
            params.merge!(
              type:         Orbf::RulesEngine::Variable::Types::ACTIVITY_RULE,
              payment_rule: nil
            )
          )
        end

        def new_activity(params)
          Variable.with(
            params.merge!(
              type:         Orbf::RulesEngine::Variable::Types::ACTIVITY,
              formula:      nil,
              payment_rule: nil
            )
          )
        end

        def new_alias(params)
          Variable.with(
            params.merge!(
              type:         Orbf::RulesEngine::Variable::Types::ALIAS
            )
          )
        end
      end

      module Types
        ACTIVITY_CONSTANT = "activity_constant"
        ACTIVITY_RULE = "activity_rule"
        ACTIVITY_RULE_DECISION = "activity_rule_decision"
        PACKAGE_RULE_DECISION = "package_rule_decision"
        ACTIVITY = "activity"
        CONTRACT = "contract"
        PACKAGE_RULE = "package_rule"
        PAYMENT_RULE = "payment_rule"
        ZONE_RULE = "zone_rule"
        ALIAS = "alias"
        TYPES = [
          ACTIVITY_CONSTANT,
          ACTIVITY_RULE,
          ACTIVITY_RULE_DECISION,
          PACKAGE_RULE_DECISION,
          ACTIVITY,
          CONTRACT,
          PACKAGE_RULE,
          PAYMENT_RULE,
          ZONE_RULE,
          ALIAS
        ].freeze
      end

      attributes  :key, :period, :expression, :type, :state, :activity_code, :orgunit_ext_id, :formula, :package, :payment_rule

      attr_reader :dhis2_period

      def initialize(key: nil, period: nil, expression: nil, type: nil, state: nil, activity_code: nil, orgunit_ext_id: nil, formula: nil, package: nil, payment_rule: nil)
        @key = key
        @period = period
        @expression = expression
        @type = type
        @state = state
        @activity_code = activity_code
        @orgunit_ext_id = orgunit_ext_id
        @formula = formula
        @package = package
        @payment_rule = payment_rule
        after_init
      end

      attr_reader :key, :period, :expression, :type, :state, :activity_code, :orgunit_ext_id, :formula, :package, :payment_rule

      def exportable?
        !!(orgunit_ext_id && dhis2_data_element)
      end

      def dhis2_in_data_element
        return nil if type != Types::ACTIVITY
        activity = package.activities.detect { |activity| activity.activity_code == activity_code }
        return nil unless activity
        activity_state = activity.activity_states.detect do |as|
          as.state == state || as.state + "_zone_main_orgunit" == state || as.state + "_raw" == state
        end

        activity_state&.ext_id
      end

      def dhis2_data_element
        formula&.dhis2_mapping(activity_code)
      end

      def inspect
        "Variable(" + [
          key, period,
          expression, type, state,
          activity_code,
          orgunit_ext_id,
          package&.code,
          payment_rule&.code
        ].join(", ") + ")"
      end

      def payment_rule_type?
        type == Types::PAYMENT_RULE
      end

      protected

      def values
        @values ||= {
          key:            @key,
          period:         @period,
          expression:     @expression,
          type:           @type,
          state:          @state,
          activity_code:  @activity_code,
          orgunit_ext_id: @orgunit_ext_id,
          formula:        @formula,
          package:        @package,
          payment_rule:   @payment_rule
        }
      end

      private

      def after_init
        @dhis2_period = if formula&.frequency
                          Orbf::RulesEngine::PeriodIterator.periods(period, formula.frequency).last
                        else
                          period
                        end

        raise "Variable type '#{type}' must be one of #{Types::TYPES}" unless Types::TYPES.include?(type.to_s)
      end
    end
  end
end
