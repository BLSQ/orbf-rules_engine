# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Package
      FREQUENCIES = %w[monthly quarterly].freeze
      KINDS = %w[single subcontract zone].freeze

      attr_reader :activities, :kind, :rules, :frequency, :code,
                  :org_unit_group_ext_ids, :groupset_ext_id, :dataset_ext_ids

      def initialize(args)
        @kind = args[:kind].to_s if args[:kind]
        @rules = args[:rules]
        @code  = args[:code].to_s
        @rules.each do |rule|
          rule.package = self
        end
        @activities = args[:activities]
        @frequency = args[:frequency].to_s if args[:frequency]
        @org_unit_group_ext_ids = Array(args[:org_unit_group_ext_ids])
        @groupset_ext_id = args[:groupset_ext_id]
        @dataset_ext_ids = args[:dataset_ext_ids]
        validate
      end

      def frequency=(f)
        @frequency = f.to_s
      end

      def monthly?
        frequency == 'monthly'
      end

      def quarterly?
        frequency == 'quarterly'
      end

      def states
        @states ||= Set.new(activities.flat_map(&:states).map(&:to_s))
      end

      def all_activities_codes
        Set.new(activities.map(&:activity_code))
      end

      def package_rules
        rules.select(&:package_kind?)
      end

      def zone_rules
        rules.select(&:zone_kind?)
      end

      def activity_rules
        rules.select(&:activity_kind?)
      end

      def activity_dependencies
        activity_rules.flat_map(&:formulas).flat_map(&:dependencies).to_set
      end

      def single?
        kind == 'single'
      end

      def subcontract?
        kind == 'subcontract'
      end

      def zone?
        kind == 'zone'
      end

      private

      def validate
        raise "Frequency #{frequency} must be one of #{FREQUENCIES}" unless FREQUENCIES.include?(frequency)
        raise "Kind #{kind} must be one of #{KINDS}" unless KINDS.include?(kind)
        raise "groupset_ext_id #{groupset_ext_id} for #{kind} not provided" if %w[subcontract zone].include?(kind) && groupset_ext_id.nil?
      end
    end
  end
end
