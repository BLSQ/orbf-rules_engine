# frozen_string_literal: true

module Orbf
  module RulesEngine
    class ActivityFormulaVariablesBuilder
      include VariablesBuilderSupport

      def initialize(package, orgunits, period)
        @package = package
        @orgunits = if package.subcontract?
                      orgunits[0..0]
                    else
                      orgunits
                    end
        @period = period
      end

      def to_variables
        activity_formula_variables
      end

      private

      attr_reader :package, :orgunits, :period

      def activity_formula_variables
        orgunits.each_with_object([]) do |orgunit, array|
          package.all_activities_codes.each do |activity_code|
            package.activity_rules.flat_map(&:formulas).each do |formula|
              substitued = ActivityFormulaValuesExpander.new(
                package.code, activity_code, formula, orgunit, period
              ).expand_values
              array.push(build_variable(orgunit, activity_code, formula, substitued))
            end
          end
        end
      end

      def build_variable(orgunit, activity_code, formula, substitued)
        Orbf::RulesEngine::Variable.with(
          period:         period,
          key:            suffix_for_activity(package.code, activity_code, formula.code, orgunit, period),
          expression:     Tokenizer.replace_token_from_expression(
            substitued,
            substitutions(activity_code),
            orgunit_parent_level1_id: orgunit.parent_ext_ids.first,
            orgunit_id:               orgunit.ext_id,
            period:                   period.downcase
          ),
          state:          formula.code,
          type:           Orbf::RulesEngine::Variable::Types::ACTIVITY_RULE,
          activity_code:  activity_code,
          orgunit_ext_id: orgunit.ext_id,
          formula:        formula,
          package:        package
        )
      end

      def substitutions(activity_code)
        states_substitutions(activity_code)
          .merge(level_substitutions(activity_code))
          .merge(package_substitutions)
          .merge(formulas_substitutions(activity_code))
          .merge(decision_table_substitutions(activity_code))
          .merge(orgunit_counts_substitutions(activity_code))
      end

      def orgunit_counts_substitutions(activity_code)
        return {} unless package.subcontract?
        counts = Orbf::RulesEngine::ContractVariablesBuilder::COUNTS
        counts.each_with_object({}) do |count, hash|
          hash[count] = suffix_activity_pattern(package.code, activity_code, count)
        end
      end

      def states_substitutions(activity_code)
        package.activities.each_with_object({}) do |activity, hash|
          next if activity_code != activity.activity_code
          activity.activity_states.each do |activity_state|
            hash[activity_state.state.to_s] = activity_state_substitution(package.code, activity, activity_state)
          end
        end
      end

      def level_substitutions(activity_code)
        package.states.each_with_object({}) do |state, hash|
          state_level1 = state + "_level1"
          hash[state_level1] = suffix_activity_pattern(package.code, activity_code, state_level1, :orgunit_parent_level1_id)
        end
      end

      def package_substitutions
        package.package_rules.flat_map(&:formulas).each_with_object({}) do |formula, hash|
          hash[formula.code] = suffix_package_pattern(package.code, formula.code)
        end
      end

      def formulas_substitutions(activity_code)
        package.activity_rules.flat_map(&:formulas).each_with_object({}) do |formula, hash|
          hash[formula.code] = suffix_activity_pattern(package.code, activity_code, formula.code)
        end
      end

      def decision_table_substitutions(activity_code)
        package.activity_rules
               .flat_map(&:decision_tables)
               .each_with_object({}) do |decision_table, hash|
          decision_table.headers(:out).each do |header_out|
            hash[header_out] = suffix_activity_pattern(package.code, activity_code, header_out)
          end
        end
      end

      def activity_state_substitution(package_code, activity, activity_state)
        if activity_state.data_element?
          suffix_activity_pattern(package_code, activity.activity_code, activity_state.state)
        elsif activity_state.constant?
          name_constant(activity.activity_code, activity_state.state, period)
        else
          raise "Unsupported activity state"
        end
      end
    end
  end
end
