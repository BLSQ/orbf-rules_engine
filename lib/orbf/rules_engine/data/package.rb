# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Package
      module Frequencies
        MONTHLY = "monthly"
        QUARTERLY = "quarterly"
        FREQUENCIES = [MONTHLY, QUARTERLY].freeze

        def self.assert_valid(package_frequency)
          return if FREQUENCIES.include?(package_frequency)
          raise "Invalid package frequency '#{package_frequency}' only supports #{FREQUENCIES}"
        end
      end

      module Kinds
        SINGLE = "single"
        SUBCONTRACT = "subcontract"
        ZONE = "zone"
        KINDS = [SINGLE, SUBCONTRACT, ZONE].freeze

        def self.assert_valid(package_kind)
          return if KINDS.include?(package_kind)
          raise "Invalid package kind '#{rule_kind}' only supports #{KINDS}"
        end
      end

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
        frequency == Frequencies::MONTHLY
      end

      def quarterly?
        frequency == Frequencies::QUARTERLY
      end

      def states
        @states ||= Set.new(activities.flat_map(&:states))
      end

      def all_activities_codes
        @all_activities_codes ||=Set.new(activities.map(&:activity_code))
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
        existing_activity_states.concat(missing_activity_states)
      end

      def package_rules
        @package_rules ||= rules.select(&:package_kind?).freeze
      end

      def zone_rules
        @zone_rules ||= rules.select(&:zone_kind?).freeze
      end

      def activity_rules
        @activity_rules ||= rules.select(&:activity_kind?).freeze
      end

      def entities_aggregation_rules
        rules.select(&:entities_aggregation_kind?)
      end

      def activity_dependencies
        @activity_dependencies ||= activity_rules.flat_map(&:formulas).flat_map(&:dependencies).to_set
      end

      def single?
        kind == Kinds::SINGLE
      end

      def subcontract?
        kind == Kinds::SUBCONTRACT
      end

      def zone?
        kind == Kinds::ZONE
      end

      def activity(activity_code)
        activities.detect { |activity| activity.activity_code == activity_code }
      end

      private

      def validate
        Frequencies.assert_valid(frequency)
        Kinds.assert_valid(kind)
        raise "groupset_ext_id #{groupset_ext_id} for #{kind} not provided" if [Kinds::SUBCONTRACT, Kinds::ZONE].include?(kind) && groupset_ext_id.nil?
        validate_values_references
        validate_states_and_activity_formula_code_uniqness
      end

      def validate_values_references
        allowed_codes = (activity_rules + zone_rules).flat_map(&:formulas).map { |f| f.code + "_values" }.to_set
        package_rules.flat_map(&:formulas).each do |formula|
          formula.values_dependencies.each do |dependency|
            next if allowed_codes.include?(dependency)
            raise "#{formula.code}, #{formula.expression} cant reference unknown dependency values #{dependency} #{allowed_codes.to_a.join(',')}"
          end
        end
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
