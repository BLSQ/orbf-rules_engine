# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Variable < Orbf::RulesEngine::ValueObject
      attributes  :key, :period, :expression, :type, :state, :activity_code,
                  :orgunit_ext_id, :formula, :package

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
        orgunit_ext_id && dhis2_data_element
      end

      def dhis2_data_element
        formula&.dhis2_mapping(activity_code)
      end

      def inspect
        ["variable", key, period, expression, type, state, activity_code,
         orgunit_ext_id].join("-")
      end

      private

      def after_init
        raise "Variable type '#{type}' must be one of #{Types::TYPES}" unless Types::TYPES.include?(type.to_s)
      end
    end
  end
end
