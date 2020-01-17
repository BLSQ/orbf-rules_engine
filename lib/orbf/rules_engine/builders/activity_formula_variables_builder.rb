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
        @tokens = {}
        @period_facts = Orbf::RulesEngine::PeriodFacts.for(period, package.calendar)
        @package_rule_codes = package.package_rules.flat_map(&:formulas).map(&:code).to_set
        @activity_rule_codes = package.activity_rules.flat_map(&:formulas).map(&:code).to_set
      end

      def to_variables
        return [] if package.loop_over_combo
        activity_formula_variables
      end

      private

      attr_reader :package, :orgunits, :period

      def activity_formula_variables
        orgunits.each_with_object([]) do |orgunit, array|
          package.all_activities_codes.each do |activity_code|
            activity = package.activities.detect { |candidate| candidate.activity_code == activity_code }
            package.activity_rules.each do |rule|
              rule.formulas.each do |formula|
                instantiated_formula = instantiate_formula(formula, activity, orgunit)
                expand_aggregation_values(instantiated_formula, activity)
                Orbf::RulesEngine::ActivityFormulaValuesExpander.new(
                  package.code, activity_code,
                  instantiated_formula,
                  formula.values_dependencies,
                  formula.rule.kind, orgunit, period,
                  package.calendar
                ).expand_values
                array << build_variable(orgunit, activity_code, formula, instantiated_formula)
              end
            end
          end
        end
      end

      # to avoid tokenizing over and over,
      # we tokenize once and reuse the token array to instantiate the expression
      def instantiate_formula(formula, activity, orgunit)
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
          else
            subs[dependency] = suffix_for_id_activity(package.code, activity.activity_code, dependency, orgunit.ext_id, period)
          end
        end
        @tokens[formula].map { |token| subs[token] || token }.join
      end

      def build_variable(orgunit, activity_code, formula, substitued)
        Orbf::RulesEngine::Variable.new_activity_rule(
          period:                  period,
          key:                     variable_key(package, orgunit, activity_code, formula, period),
          expression:              substitued,
          state:                   formula.code,
          type:                    Orbf::RulesEngine::Variable::Types::ACTIVITY_RULE,
          activity_code:           activity_code,
          orgunit_ext_id:          orgunit.ext_id,
          formula:                 formula,
          package:                 package,
          exportable_variable_key: exportable_variable_key(package, orgunit, activity_code, formula, period)
        )
      end

      ### Aggregation SumIf related expansions

      def expand_aggregation_values(instantiated_formula, activity)
        entities_aggregation_values(activity).each do |k, v|
          # gsub! is safe as the expression has already been instantiated
          # and produced a new string instance
          instantiated_formula.gsub!("%{#{k}}", v)
        end
      end

      def entities_aggregation_values(activity)
        package.entities_aggregation_rules.each_with_object({}) do |aggregation_rules, hash|
          aggregation_rules.formulas.each do |formula|
            selected_org_units = SumIf.org_units(@all_orgunits, package, activity)
            key = formula.code + "_values"
            hash[key.to_sym] = to_values_list(formula, activity, selected_org_units)
          end
        end
      end

      def to_values_list(formula, activity, selected_org_units)
        vals = selected_org_units.map do |orgunit|
          suffix_for_id_activity(package.code, activity.activity_code, suffix_raw(formula.code), orgunit.ext_id, period)
        end
        vals.empty? ? "0" : vals.join(", ")
      end
    end
  end
end
