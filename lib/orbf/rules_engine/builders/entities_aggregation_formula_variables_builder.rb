# frozen_string_literal: true

module Orbf
  module RulesEngine
    class EntitiesAggregationFormulaVariablesBuilder
      include VariablesBuilderSupport

      def initialize(package, orgunits, period)
        @package = package
        @orgunits = orgunits
        @period = period
      end

      def to_variables
        entities_aggregation_rules = package.entities_aggregation_rules.select { |r| r.formulas.any? }
        return [] unless package.subcontract? && entities_aggregation_rules.any?
        orgunits.each_with_object([]) do |orgunit, variables|
          entities_aggregation_rules.each do |aggreggation_rule|
            package.all_activities_codes.each do |activity_code|
              aggreggation_rule.formulas.each do |formula|
                key = suffix_for_activity(
                  package.code,
                  activity_code,
                  suffix_raw(formula.code),
                  orgunit, period
                )

                expression = Tokenizer.replace_token_from_expression(
                  formula.expression,
                  substitutions(activity_code),
                  orgunit_id: orgunit.ext_id,
                  period:     period.downcase
                )
                variables.push(
                  Orbf::RulesEngine::Variable.with(
                    period:         period,
                    key:            key,
                    expression:     expression,
                    state:          formula.code,
                    type:           Orbf::RulesEngine::Variable::Types::CONTRACT,
                    activity_code:  activity_code,
                    orgunit_ext_id: orgunit.ext_id,
                    formula:        formula,
                    package:        package,
                    payment_rule:   nil
                  )
                )
              end
            end
          end
        end
      end

      private

      attr_reader :package, :orgunits, :period

      def substitutions(activity_code)
        states_substitutions(activity_code).merge(formulas_substitutions(activity_code))
      end

      def states_substitutions(activity_code)
        package.activities.each_with_object({}) do |activity, hash|
          next if activity_code != activity.activity_code
          package.harmonized_activity_states(activity).each do |activity_state|
            hash[activity_state.state.to_s] = activity_state_substitution(
              package.code,
              activity,
              activity_state
            )
          end
        end
      end

      def formulas_substitutions(activity_code)
        package.entities_aggregation_rules
               .flat_map(&:formulas)
               .each_with_object({}) do |formula, hash|
          hash[formula.code] = suffix_activity_pattern(
            package.code,
            activity_code,
            suffix_raw(formula.code)
          )
        end
      end

      def activity_state_substitution(package_code, activity, activity_state)
        if activity_state.data_element?
          suffix_activity_pattern(package_code, activity.activity_code, suffix_raw(activity_state.state))
        elsif activity_state.constant?
          name_constant(activity.activity_code, activity_state.state, period)
        elsif activity_state.indicator?
          suffix_activity_pattern(package_code, activity.activity_code, suffix_raw(activity_state.state))
        else
          raise "Unsupported activity state"
        end
      end
    end
   end
end
