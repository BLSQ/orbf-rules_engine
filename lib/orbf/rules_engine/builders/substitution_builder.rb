module Orbf
  module RulesEngine
    class SubstitutionBuilder
      include VariablesBuilderSupport
      EMPTY_SUBSTITUTIONS = {}.freeze
      LEVELS_RANGES = (1..5).freeze
      attr_accessor :package, :expression, :activity_code, :period

      def initialize(package:, expression:, activity_code:, period:)
        @package = package
        @expression = expression
        @activity_code = activity_code
        @period = period
      end

      def call
        hashes = [
          states_substitutions,
          null_substitutions,
          level_substitutions,
          package_substitutions,
          formulas_substitutions,
          zone_main_orgunit_substitutions,
          decision_table_substitutions,
          orgunit_counts_substitutions,
          dates_substitutions
        ].reject(&:empty?)
        hashes.each_with_object({}) { |hash, acc| acc.merge!(hash) }
      end

      def states_substitutions
        package.activities.each_with_object({}) do |activity, hash|
          next if activity_code != activity.activity_code

          package.harmonized_activity_states(activity).each do |activity_state|
            next unless used_in_expression?(activity_state.state)
            hash[activity_state.state] = activity_state_substitution(package.code, activity, activity_state)
          end
        end
      end

      def null_substitutions
        activity = package.activities.detect { |candidate| candidate.activity_code == activity_code }
        package.harmonized_activity_states(activity).each_with_object({}) do |activity_state, hash|
          suffixed_state = suffix_is_null(activity_state.state)
          next unless used_in_expression?(activity_state.state)

          hash[suffixed_state] = suffix_activity_pattern(package.code, activity_code, suffixed_state)
        end
      end

      def level_substitutions
        return EMPTY_SUBSTITUTIONS unless expression.include?("_level_")

        package.states.each_with_object({}) do |state, hash|
          LEVELS_RANGES.each do |level_index|
            state_level = state + "_level_#{level_index}"
            next unless used_in_expression?(state_level)

            hash[state_level] = suffix_activity_pattern(
              package.code, activity_code, state_level,
              "orgunit_parent_level#{level_index}_id".to_sym
            )
          end
        end
      end

      def package_substitutions
        result = package.package_rules.flat_map(&:formulas).each_with_object({}) do |formula, hash|
          next unless used_in_expression?(formula.code)

          hash[formula.code] = suffix_package_pattern(package.code, formula.code)
        end
        result
      end

      def formulas_substitutions
        package.activity_rules.flat_map(&:formulas).each_with_object({}) do |formula, hash|
          next unless used_in_expression?(formula.code)

          hash[formula.code] = suffix_activity_pattern(package.code, activity_code, formula.code)
        end
      end

      def zone_main_orgunit_substitutions
        return EMPTY_SUBSTITUTIONS unless used_in_expression?("_zone_main_orgunit")

        activity = package.activities.detect { |candidate| candidate.activity_code == activity_code }
        package.harmonized_activity_states(activity).each_with_object({}) do |activity_state, hash|


          state_level = activity_state.state + "_zone_main_orgunit"
          next unless used_in_expression?(state_level)

          hash[state_level] = suffix_activity_pattern(
            package.code, activity_code, state_level,
            "zone_main_orgunit_id".to_sym
          )
        end
      end

      def decision_table_substitutions
        package.activity_rules
               .flat_map(&:decision_tables)
               .each_with_object({}) do |decision_table, hash|
          decision_table.headers(:out).each do |header_out|
            next unless used_in_expression?(header_out)
            hash[header_out] = suffix_activity_pattern(package.code, activity_code, header_out)
          end
        end
      end

      def orgunit_counts_substitutions
        return EMPTY_SUBSTITUTIONS unless package.subcontract?

        counts = Orbf::RulesEngine::ContractVariablesBuilder::COUNTS
        counts.each_with_object({}) do |count, hash|
          next unless used_in_expression?(count)

          hash[count] = suffix_activity_pattern(package.code, activity_code, count)
        end
      end

      def dates_substitutions
        @period_facts ||= Orbf::RulesEngine::PeriodFacts.for(period)
      end

      private

      def used_in_expression?(code)
        !!expression[code]
      end

      def activity_state_substitution(package_code, activity, activity_state)
        if activity_state.data_element?
          suffix_activity_pattern(package_code, activity.activity_code, activity_state.state)
        elsif activity_state.constant?
          name_constant(activity.activity_code, activity_state.state, period)
        elsif activity_state.indicator?
          suffix_activity_pattern(package_code, activity.activity_code, activity_state.state)
        else
          raise "Unsupported activity state"
        end
      end
    end
  end
end
