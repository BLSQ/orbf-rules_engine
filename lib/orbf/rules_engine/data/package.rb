# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Package
      FREQUENCIES = %w[monthly quarterly].freeze
      KINDS = %w[single subcontract zone].freeze

      attr_reader :activities, :kind, :rules, :frequency, :code,
                  :org_unit_group_ext_ids, :groupset_ext_id, :dataset_ext_ids

      KNOWN_ATTRIBUTES = %i[kind rules code activities frequency
                            org_unit_group_ext_ids groupset_ext_id dataset_ext_ids].freeze

      def initialize(args)
        Assertions.valid_arg_keys!(args, KNOWN_ATTRIBUTES)
        @rules = Array(args[:rules])
        @org_unit_group_ext_ids = Array(args[:org_unit_group_ext_ids])
        @activities = Array(args[:activities])
        @kind = args[:kind].to_s if args[:kind]
        @code = args[:code].to_s
        @rules.each do |rule|
          rule.package = self
        end
        @frequency = args[:frequency].to_s if args[:frequency]
        @groupset_ext_id = args[:groupset_ext_id]
        @dataset_ext_ids = args[:dataset_ext_ids]
        validate
      end

      def frequency=(f)
        @frequency = f.to_s
      end

      def monthly?
        frequency == "monthly"
      end

      def quarterly?
        frequency == "quarterly"
      end

      def states
        @states ||= Set.new(activities.flat_map(&:states).map(&:to_s))
      end

      def all_activities_codes
        Set.new(activities.map(&:activity_code))
      end

      def harmonized_activity_states(activity)
        all_states = states.to_a
        existing_activity_states = activity.activity_states
        missing_states = all_states - existing_activity_states.map(&:state)
        missing_activity_states = missing_states.map do |state|
          ActivityState.new_data_element(
            state:  state,
            name:   activity.activity_code + "-" + state,
            ext_id: "fakeone"
          )
        end
        existing_activity_states + missing_activity_states
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

      def entities_aggregation_rules
        rules.select(&:entities_aggregation_kind?)
      end

      def activity_dependencies
        activity_rules.flat_map(&:formulas).flat_map(&:dependencies).to_set
      end

      def single?
        kind == "single"
      end

      def subcontract?
        kind == "subcontract"
      end

      def zone?
        kind == "zone"
      end

      private

      def validate
        raise "Frequency #{frequency} must be one of #{FREQUENCIES}" unless FREQUENCIES.include?(frequency)
        raise "Kind #{kind} must be one of #{KINDS}" unless KINDS.include?(kind)
        raise "groupset_ext_id #{groupset_ext_id} for #{kind} not provided" if %w[subcontract zone].include?(kind) && groupset_ext_id.nil?

        validate_states_and_activity_formula_code_uniqness
      end

      def validate_states_and_activity_formula_code_uniqness
        states = activities.flat_map(&:activity_states).flat_map(&:state)
        codes = activity_rules.flat_map(&:formulas).map(&:code)
        commons = states & codes
        raise "activity states and activity formulas with same code : #{commons}" if commons.any?
      end
    end
  end
end
