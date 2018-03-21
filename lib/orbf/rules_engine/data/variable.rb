# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Variable < Orbf::RulesEngine::ValueObject
      attributes  :key, :period, :expression, :type, :state, :activity_code,
                  :orgunit_ext_id, :formula, :package, :payment_rule

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

        def new_activity_constant(params)
          Variable.with(
            params.merge!(
              type:           Orbf::RulesEngine::Variable::Types::ACTIVITY_CONSTANT,
              orgunit_ext_id: nil,
              formula:        nil,
              payment_rule:   nil
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
      end

      module Types
        ACTIVITY_CONSTANT = "activity_constant"
        ACTIVITY_RULE = "activity_rule"
        ACTIVITY_RULE_DECISION = "activity_rule_decision"
        ACTIVITY = "activity"
        CONTRACT = "contract"
        PACKAGE_RULE = "package_rule"
        PAYMENT_RULE = "payment_rule"
        ZONE_RULE = "zone_rule"
        TYPES = [
          ACTIVITY_CONSTANT,
          ACTIVITY_RULE,
          ACTIVITY_RULE_DECISION,
          ACTIVITY,
          CONTRACT,
          PACKAGE_RULE,
          PAYMENT_RULE,
          ZONE_RULE
        ].freeze
      end

      def exportable?
        !!(orgunit_ext_id && dhis2_data_element)
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

      private

      def after_init
        raise "Variable type '#{type}' must be one of #{Types::TYPES}" unless Types::TYPES.include?(type.to_s)
      end
    end
  end
end
