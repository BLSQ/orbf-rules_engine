# frozen_string_literal: true

module Orbf
  module RulesEngine
    class ActivityFormulaComboVariablesBuilder
      include VariablesBuilderSupport

      def initialize(package, orgunits, period)
        @package = package
        @all_orgunits = orgunits
        @orgunits = orgunits.out_list
        @period = period
        @tokens = {}
        @period_facts = Orbf::RulesEngine::PeriodFacts.for(period)
        @package_rule_codes = package.package_rules.flat_map(&:formulas).map(&:code).to_set
        @activity_rule_codes = package.activity_rules.flat_map(&:formulas).map(&:code).to_set
      end

      def to_variables
        return nil unless package.loop_over_combo

        activity_formula_variables
      end

      private

      attr_reader :package, :orgunits, :period

      def activity_formula_variables
        orgunits.each_with_object([]) do |orgunit, array|
          package.all_activities_codes.each do |activity_code|
            activity = package.activities.detect { |candidate| candidate.activity_code == activity_code }
            package.loop_over_combo[:category_option_combos].each do |category_option_combo|
              package.activity_rules.each do |rule|
                rule.formulas.each do |formula|
                  instantiated_formula = instantiate_formula(formula, activity, orgunit, category_option_combo)
                  Orbf::RulesEngine::ActivityFormulaValuesExpander.new(
                    package.code, activity_code,
                    instantiated_formula,
                    formula.values_dependencies,
                    formula.rule.kind, orgunit, period
                  ).expand_values
                  array << build_variable(orgunit, activity_code, formula, instantiated_formula, category_option_combo)
                end
              end
            end
          end
        end
      end

      # to avoid tokenizing over and over,
      # we tokenize once and reuse the token array to instantiate the expression
      def instantiate_formula(formula, activity, orgunit, category_option_combo)
        @tokens[formula] ||= Orbf::RulesEngine::Tokenizer.tokenize(formula.expression)
        subs = {}
        formula.dependencies.each do |dependency|
          activity_state = activity.activity_states.find { |s| s.state == dependency }

          if @period_facts[dependency]
            subs[dependency] = @period_facts[dependency]
          elsif activity_state&.constant?
            subs[dependency] = name_constant(activity.activity_code, activity_state.state, period)
          elsif dependency.end_with?("_level_1", "_level_2", "_level_3", "_level_4", "_level_5")
            level = dependency[-1].to_i
            parent_id = orgunit.parent_ext_ids[level - 1]
            subs[dependency] = suffix_for_id_activity(package.code, activity.activity_code, dependency, parent_id, period)
          elsif dependency.end_with?("_level_1_quarterly", "_level_2_quarterly", "_level_3_quarterly", "_level_4_quarterly", "_level_5_quarterly")
            level = dependency[-11].to_i
            parent_id = orgunit.parent_ext_ids[level - 1]
            subs[dependency] = suffix_for_id_activity(package.code, activity.activity_code, dependency, parent_id, period)
          elsif dependency.end_with?("_zone_main_orgunit")
            parent_id = @all_orgunits.first.ext_id
            subs[dependency] = suffix_for_id_activity(package.code, activity.activity_code, dependency, parent_id, period)
          elsif @package_rule_codes.include?(dependency) && !@activity_rule_codes.include?(dependency)
            subs[dependency] = suffix_for_package(package.code, dependency, orgunit, period)
          elsif activity_state&.data_element? && activity_state.category_combo_ext_id != package.loop_over_combo[:id]
            subs[dependency] = suffix_for_id_activity(package.code, activity.activity_code, dependency, orgunit.ext_id, period)
          else
            subs[dependency] = suffix_for_id_activity(package.code, activity.activity_code + "_" + (category_option_combo[:id] || category_option_combo["id"]), dependency, orgunit.ext_id, period)
          end
        end
        @tokens[formula].map { |token| subs[token] || token }.join
      end

      def build_variable(orgunit, activity_code, formula, substitued, category_option_combo)
        Orbf::RulesEngine::Variable.new_activity_rule(
          period:                       period,
          key:                          variable_key(package, orgunit, activity_code + "_" + (category_option_combo[:id] || category_option_combo["id"]), formula, period),
          expression:                   substitued,
          state:                        formula.code,
          type:                         Orbf::RulesEngine::Variable::Types::ACTIVITY_RULE,
          activity_code:                activity_code,
          orgunit_ext_id:               orgunit.ext_id,
          formula:                      formula,
          package:                      package,
          exportable_variable_key:      exportable_variable_key(package, orgunit, activity_code, formula, period),
          category_option_combo_ext_id: category_option_combo[:id]
        )
      end
    end
  end
end
