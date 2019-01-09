# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Project
      attr_reader :packages, :payment_rules, :dhis2_params,
                  :default_category_option_combo_ext_id, :default_attribute_option_combo_ext_id,
                  :engine_version

      def initialize(args)
        @packages = args[:packages] || []
        @payment_rules = args[:payment_rules] || []
        @dhis2_params = args[:dhis2_params] || {}
        @default_category_option_combo_ext_id = args[:default_category_combo_ext_id]
        @default_attribute_option_combo_ext_id = args[:default_attribute_option_combo_ext_id]
        @engine_version = args.fetch(:engine_version, 3)
      end

      def indicators
        packages
          .flat_map(&:activities)
          .flat_map(&:activity_states)
          .select(&:indicator?)
      end

      def default_combos_ext_ids
        {
          default_category_option_combo_ext_id:  default_category_option_combo_ext_id,
          default_attribute_option_combo_ext_id: default_attribute_option_combo_ext_id
        }
      end

      def to_json(options = nil)
        to_h.to_json(options)
      end

      def to_h
        {
          payment_rules:          payment_rules.map(&:to_h),
          default_combos_ext_ids: default_combos_ext_ids,
          dhis2_params:           dhis2_params
        }
      end
    end
  end
end
