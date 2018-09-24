# frozen_string_literal: true

module Orbf
  module RulesEngine
    class PackageVariablesBuilder
      include VariablesBuilderSupport

      def initialize(package, orgunits, period)
        @package = package
        @orgunits = orgunits.out_list
        @period = period
      end

      def to_variables
        org_package_formula_variables
      end

      private

      attr_reader :package, :orgunits, :period

      def org_package_formula_variables
        orgunits.each_with_object([]) do |orgunit, array|
          package.package_rules.flat_map(&:formulas).each do |formula|
            substitued = Tokenizer.replace_token_from_expression(
              formula.expression,
              values(orgunit),
              orgunit_id: orgunit.ext_id,
              period:     period
            )
            array.push Orbf::RulesEngine::Variable.new_package_rule(
              period:                  period,
              key:                     suffix_for(package.code, formula.code, orgunit, period),
              expression:              format(substitued, activity_substitutions(orgunit)),
              state:                   formula.code,
              orgunit_ext_id:          orgunit.ext_id,
              formula:                 formula,
              package:                 package,
              exportable_variable_key: if formula.exportable_formula_code
                                         suffix_for(package.code, formula.exportable_formula_code, orgunit, period)
                                       end
            )
          end
        end
      end

      def values(orgunit)
        values_substitutions(orgunit).merge(package_substitutions(orgunit))
                                     .merge(zone_substitutions)
                                     .merge(decision_table_substitutions(orgunit))
      end

      def values_substitutions(orgunit)
        package.activity_rules
               .flat_map(&:formulas)
               .each_with_object({}) do |v, hash|
          hash[v.code + "_values"] = suffix_for_values(package.code, v.code, orgunit, period)
        end
      end

      def zone_substitutions
        package.zone_rules
               .flat_map(&:formulas)
               .each_with_object({}) do |formula, hash|
          hash[formula.code] = formula.code + "_for_" + downcase(period)
        end
      end

      def package_substitutions(orgunit)
        package.package_rules
               .flat_map(&:formulas)
               .each_with_object({}) do |formula, hash|
          hash[formula.code] = suffix_for(package.code, formula.code, orgunit, period)
        end
      end

      def decision_table_substitutions(orgunit)
        package.package_rules
               .flat_map(&:decision_tables)
               .each_with_object({}) do |decision_table, hash|
          decision_table.headers(:out).each do |header_out|
            hash[header_out] = suffix_for(package.code, header_out, orgunit, period)
          end
        end
      end

      def activity_substitutions(orgunit)
        package.activity_rules
               .flat_map(&:formulas)
               .each_with_object({}) do |v, hash|
          subs = package.all_activities_codes.map do |activity_code|
            suffix_for_activity(package.code, activity_code, v.code, orgunit, period)
          end
          hash[suffix_for(package.code, v.code + "_values", orgunit, period).to_sym] = subs.join(", ")
        end
      end
    end
  end
end
