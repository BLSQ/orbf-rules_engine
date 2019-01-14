# frozen_string_literal: true

module Orbf
  module RulesEngine
    class ActivityFormulaVariablesBuilder
      include VariablesBuilderSupport

      def initialize(package, orgunits, period)
        @package = package
        @all_orgunits = orgunits
        @orgunits = orgunits.out_list
        @period = period
      end

      def to_variables
        activity_formula_variables
      end

      private

      EMPTY_SUBSTITUTIONS = {}.freeze

      LEVELS_RANGES = (1..5).freeze

      attr_reader :package, :orgunits, :period

      def activity_formula_variables
        orgunits.each_with_object([]) do |orgunit, array|
          package.all_activities_codes.each do |activity_code|
            package.activity_rules.each do |rule|
              rule.formulas.each do |formula|
                substitued = ActivityFormulaValuesExpander.new(
                  package.code, activity_code, formula, orgunit, period
                ).expand_values
                substitued = format(substitued, entities_aggregation_values(activity_code))

                array.push(build_variable(orgunit, activity_code, formula, substitued))
              end
            end
          end
        end
      end

      def build_variable(orgunit, activity_code, formula, substitued)
        expression = Tokenizer.replace_token_from_expression(
          substitued,
          substitutions(formula, activity_code),
          level_pattern_values(orgunit).merge(
            orgunit_id: orgunit.ext_id,
            period:     downcase(period)
          )
        )


        Orbf::RulesEngine::Variable.new_activity_rule(
          period:                  period,
          key:                     variable_key(package, orgunit, activity_code, formula, period),
          expression:              expression,
          state:                   formula.code,
          type:                    Orbf::RulesEngine::Variable::Types::ACTIVITY_RULE,
          activity_code:           activity_code,
          orgunit_ext_id:          orgunit.ext_id,
          formula:                 formula,
          package:                 package,
          exportable_variable_key: exportable_variable_key(package, orgunit, activity_code, formula, period)
        )
      end

      def level_pattern_values(orgunit)
        hash = {}
        orgunit.parent_ext_ids.each_with_index do |ext_id, index|
          hash["orgunit_parent_level#{index + 1}_id".to_sym] = ext_id
        end
        hash[:zone_main_orgunit_id] = @all_orgunits.first.ext_id
        hash
      end

      def zone_main_orgunit_substitutions(activity_code)
        activity = package.activities.detect { |candidate| candidate.activity_code == activity_code }
        package.harmonized_activity_states(activity).each_with_object({}) do |activity_state, hash|
          state_level = activity_state.state + "_zone_main_orgunit"
          hash[state_level] = suffix_activity_pattern(
            package.code, activity_code, state_level,
            "zone_main_orgunit_id".to_sym
          )
        end
      end

      def substitutions(formula, activity_code)
        hashes = [
          states_substitutions(activity_code),
          null_substitutions(activity_code),
          level_substitutions(formula, activity_code),
          package_substitutions,
          formulas_substitutions(activity_code),
          zone_main_orgunit_substitutions(activity_code),
          decision_table_substitutions(activity_code),
          orgunit_counts_substitutions(activity_code),
          dates_substitutions()
        ]
        hashes.each_with_object({}) { |hash, acc| acc.merge!(hash) }
      end

      def dates_substitutions()
        @period_facts ||= Orbf::RulesEngine::PeriodFacts.for(period)
      end

      def null_substitutions(activity_code)
        activity = package.activities.detect { |candidate| candidate.activity_code == activity_code }
        package.harmonized_activity_states(activity).each_with_object({}) do |activity_state, hash|
          suffixed_state = suffix_is_null(activity_state.state)
          hash[suffixed_state] = suffix_activity_pattern(package.code, activity_code, suffixed_state)
        end
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

          package.harmonized_activity_states(activity).each do |activity_state|
            hash[activity_state.state] = activity_state_substitution(package.code, activity, activity_state)
          end
        end
      end

      def level_substitutions(formula, activity_code)
        return EMPTY_SUBSTITUTIONS unless formula.expression.include?("_level_")

        package.states.each_with_object({}) do |state, hash|
          LEVELS_RANGES.each do |level_index|
            state_level = state + "_level_#{level_index}"
            hash[state_level] = suffix_activity_pattern(
              package.code, activity_code, state_level,
              "orgunit_parent_level#{level_index}_id".to_sym
            )
          end
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

      def entities_aggregation_values(activity_code)
        activity = package.activities.detect { |candidate| candidate.activity_code == activity_code }

        sub = package.entities_aggregation_rules.each_with_object({}) do |aggregation_rules, hash|
          aggregation_rules.formulas.each do |formula|
            selected_org_units = SumIf.org_units(@all_orgunits, package, activity)
            key = formula.code + "_values"
            hash[key.to_sym] = to_values_list(formula, activity, selected_org_units)
          end
        end

        sub
      end

      def to_values_list(formula, activity, selected_org_units)
        vals = selected_org_units.map do |orgunit|
          suffix_for_id_activity(package.code, activity.activity_code, suffix_raw(formula.code), orgunit.ext_id, period)
        end
        vals.empty? ? "0" : vals.join(", ")
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
