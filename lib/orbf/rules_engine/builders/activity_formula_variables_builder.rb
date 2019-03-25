# frozen_string_literal: true
require_relative "./substitution_builder"
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

      attr_reader :package, :orgunits, :period

      def activity_formula_variables
        @tokens ||={}
        period_facts = Orbf::RulesEngine::PeriodFacts.for(period)
        package_rule_codes = package.package_rules.flat_map(&:formulas).map(&:code).to_set
        orgunits.each_with_object([]) do |orgunit, array|
          package.all_activities_codes.each do |activity_code|
            activity = package.activities.detect { |candidate| candidate.activity_code == activity_code }
            package.activity_rules.each do |rule|
              rule.formulas.each do |formula|
                @tokens[formula] ||= Orbf::RulesEngine::Tokenizer.tokenize(formula.expression)
                subs = {}
                formula.dependencies.each do |dependency|
                  activity_state = activity.activity_states.find { |s| s.state == dependency}
                  if period_facts[dependency]
                    subs[dependency] = period_facts[dependency]
                  elsif activity_state&.constant?
                    subs[dependency]=name_constant(activity.activity_code, activity_state.state, period)
                  elsif dependency.end_with?("_level_1") || dependency.end_with?("_level_2") || dependency.end_with?("_level_3") || dependency.end_with?("_level_4") || dependency.end_with?("_level_5")
                    level = dependency[-1].to_i
                    parent_id = orgunit.parent_ext_ids[level - 1]
                    subs[dependency]=suffix_for_id_activity(package.code, activity.activity_code, dependency, parent_id, period)
                  elsif dependency.end_with?("_zone_main_orgunit")
                    #state = dependency.slice(0, dependency.length - 18)
                    parent_id = @all_orgunits.first.ext_id
                    subs[dependency]=suffix_for_id_activity(package.code, activity.activity_code, dependency, parent_id, period)
                  elsif package_rule_codes.include?(dependency)
                    subs[dependency]=suffix_for_package(package.code, dependency, orgunit, period)
                  else
                    subs[dependency]=suffix_for_id_activity(package.code, activity.activity_code, dependency, orgunit.ext_id, period)
                  end
                end
                instantiated_formula = @tokens[formula].map {|token| subs[token] || token }.join()
                instantiated_formula = expand_aggregation_values(instantiated_formula, activity)
                instantiated_formula = Orbf::RulesEngine::ActivityFormulaValuesExpanderNew.new(
                  package.code, activity_code,
                  instantiated_formula,
                  formula.values_dependencies,
                  formula.rule.kind, orgunit, period
                ).expand_values
                array << build_variable(orgunit, activity_code, formula, instantiated_formula)
              end
            end
          end
        end
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

      def expand_aggregation_values(instantiated_formula, activity)
         values_expansions = entities_aggregation_values(activity)
         values_expansions.each do |k, v|
           instantiated_formula.gsub!("%{#{k}}", v)
        end

         instantiated_formula
      end

      def entities_aggregation_values(activity)
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
    end
  end
end

# frozen_string_literal: true

module Orbf
  module RulesEngine
    class ActivityFormulaValuesExpanderNew
      include VariablesBuilderSupport

      def initialize(package_code, activity_code, expression, values_dependencies, rule_kind, orgunit, period)
        @package_code = package_code
        @activity_code = activity_code
        @expression = expression
        @rule_kind = rule_kind
        @values_dependencies = values_dependencies
        @orgunit = orgunit
        @period = period
      end

      # turn %{..._values} in to their :
      #    activity_code_code_for_orgunit_id_and_period_1,
      #    activity_code_code_for_orgunit_id_and_period_2
      # in the expression formula for a given orgunit, period and activity code
      def expand_values
        expanded_string = expression
        spans_subsitutions.each do |k, v|
          expanded_string.gsub!("%{#{k}}", v)
        end
        expanded_string
      end

      private

      attr_reader :package_code, :activity_code, :rule_kind, :expression, :orgunit, :period, :values_dependencies

      # return hash with values to susbstitute in the formula
      #   key is dependency symbol and values is the joined values
      #       activity_code_code_for_orgunit_id_and_period_1,
      #       activity_code_code_for_orgunit_id_and_period_2
      def spans_subsitutions
        values_dependencies.each_with_object({}) do |dependency, hash|
          span = Orbf::RulesEngine::Spans.matching_span(dependency, rule_kind)
          next unless span
          next if hash[dependency.to_sym]

          hash[dependency.to_sym] = to_values_list(span, dependency)
        end
      end

      def to_values_list(span, dependency)
        periods = span.periods(period, dependency)
        code = span.prefix(dependency)
        val = periods.map do |period|
          suffix_for_id_activity(package_code, activity_code, code, orgunit.ext_id, period)
        end
        val.join(",")
      end
    end
  end
end
