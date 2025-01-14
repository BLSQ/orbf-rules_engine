# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Package
      module Frequencies
        MONTHLY = "monthly"
        QUARTERLY = "quarterly"
        QUARTERLY_NOV = "quarterly_nov"
        FREQUENCIES = [MONTHLY, QUARTERLY_NOV, QUARTERLY].freeze

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
                  :main_org_unit_group_ext_ids, :target_org_unit_group_ext_ids,
                  :groupset_ext_id, :dataset_ext_ids,
                  :matching_groupset_ext_ids, :include_main_orgunit, :loop_over_combo,
                  :deg_ext_id
      attr_accessor :project
      KNOWN_ATTRIBUTES = %i[kind rules code activities frequency
                            main_org_unit_group_ext_ids
                            target_org_unit_group_ext_ids
                            groupset_ext_id dataset_ext_ids
                            matching_groupset_ext_ids include_main_orgunit
                            loop_over_combo project deg_ext_id].freeze

      def initialize(args)
        Assertions.valid_arg_keys!(args, KNOWN_ATTRIBUTES)
        @rules = Array(args[:rules])
        @main_org_unit_group_ext_ids = Array(args[:main_org_unit_group_ext_ids])
        @target_org_unit_group_ext_ids = Array(args[:target_org_unit_group_ext_ids])
        @activities = Array(args[:activities])
        @kind = args[:kind].to_s if args[:kind]
        @code = args[:code].to_s
        @loop_over_combo = args[:loop_over_combo]
        @rules.each do |rule|
          rule.package = self
        end
        @frequency = args[:frequency].to_s if args[:frequency]
        @groupset_ext_id = args[:groupset_ext_id]
        @matching_groupset_ext_ids = Array(args[:matching_groupset_ext_ids])
        @dataset_ext_ids = args[:dataset_ext_ids]
        @include_main_orgunit = args[:include_main_orgunit]
        @project = args[:project]
        @deg_ext_id = args[:deg_ext_id]
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

      def quarterly_nov?
        frequency == Frequencies::QUARTERLY_NOV
      end

      def calendar
        project.calendar
      end

      def states
        @states ||= Set.new(activities.flat_map(&:states))
      end

      def all_activities_codes
        @all_activities_codes ||= Set.new(activities.map(&:activity_code))
      end

      def harmonized_activity_states(activity)
        all_states = states.to_a
        existing_activity_states = activity.activity_states
        missing_states = all_states - existing_activity_states.map(&:state)
        missing_activity_states = missing_states.map do |state|
          ActivityState.new_data_element(
            state:  state,
            name:   activity.activity_code + "-" + state,
            ext_id: "fakeone",
            origin: "dataValueSets"
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

      def zone_activity_rules
        @zone_activity_rules ||= rules.select(&:zone_activity_kind?).freeze
      end

      def activity_rules
        @activity_rules ||= rules.select(&:activity_kind?).freeze
      end

      def activity_related_rules
        @activity_related_rules ||= rules.select(&:activity_related_kind?).freeze
      end

      def entities_aggregation_rules
        rules.select(&:entities_aggregation_kind?)
      end

      def activity_dependencies
        @activity_dependencies ||= activity_rules.flat_map(&:formulas).flat_map(&:combined_dependencies).to_set
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

      def include_main_orgunit?
        include_main_orgunit
      end

      private

      def validate
        Frequencies.assert_valid(frequency)
        Kinds.assert_valid(kind)
        raise "groupset_ext_id #{groupset_ext_id} for #{kind} not provided" if (Kinds::SUBCONTRACT == kind) && groupset_ext_id.nil?
        raise "groupset_ext_id or target_org_unit_group_ext_ids should be provided for zone package" if (Kinds::ZONE == kind) && groupset_ext_id.nil? && target_org_unit_group_ext_ids.none?

        validate_values_references
        validate_states_and_activity_formula_code_uniqness
        validate_zone_rules
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

      def validate_zone_rules
        zone_related_rules = rules.select(&:zone_related_kind?)
        raise "Rules are zone related but the package isn't zone related" if zone_related_rules.any? && !zone?
      end
    end
  end
end
