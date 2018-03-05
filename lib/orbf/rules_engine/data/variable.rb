# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Variable < Orbf::RulesEngine::ValueObject
      attributes  :key, :period, :expression, :type, :state, :activity_code,
                  :orgunit_ext_id, :formula, :package

      TYPES = %w[activity_constant activity_rule activity_rule_decision activity contract package_rule payment_rule zone_rule].freeze

      def to_s
        inspect
      end

      def exportable?
        orgunit_ext_id && dhis2_data_element
      end

      def dhis2_data_element
        formula&.dhis2_mapping(activity_code)
      end

      private

      def after_init
        raise "Variable type '#{type}' must be one of #{TYPES}" unless TYPES.include?(type.to_s)
      end
    end
  end
end
