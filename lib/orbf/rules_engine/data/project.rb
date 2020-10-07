# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Project
      attr_reader :packages, :payment_rules, :dhis2_params,
                  :default_category_option_combo_ext_id, :default_attribute_option_combo_ext_id,
                  :engine_version, :calendar, :contract_settings, :read_through_deg

      def initialize(args)
        @packages = args[:packages] || []
        @packages.each do |package|
          package.project = self
        end
        @payment_rules = args[:payment_rules] || []
        @payment_rules.each do |package|
          package.project = self
        end
        @dhis2_params = args[:dhis2_params] || {}
        @default_category_option_combo_ext_id = args[:default_category_combo_ext_id]
        @default_attribute_option_combo_ext_id = args[:default_attribute_option_combo_ext_id]
        @engine_version = args.fetch(:engine_version, 3)
        @calendar = args[:calendar]
        @contract_settings = args[:contract_settings]
        @read_through_deg = args[:read_through_deg]
      end

      def calendar
        @calendar ||= ::Orbf::RulesEngine::GregorianCalendar.new
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
    end
  end
end
