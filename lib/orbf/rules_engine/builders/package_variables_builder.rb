# frozen_string_literal: true

module Orbf
  module RulesEngine
    class PackageVariablesBuilder
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
            array.push Orbf::RulesEngine::Variable.with(
              period:         period,
              key:            suffix_for(package.code, formula.code, orgunit, period),
              expression:     format(substitued, activity_substitions(orgunit)),
              state:          formula.code,
              type:           Orbf::RulesEngine::Variable::Types::PACKAGE_RULE,
              activity_code:  nil,
              orgunit_ext_id: orgunit.ext_id,
              formula:        formula,
              package:        package
            )
          end
        end
      end

      def values(orgunit)
        values_substitutions(orgunit).merge(substitions_package(orgunit))
                                     .merge(zone_subsititions)
      end

      def values_substitutions(orgunit)
        package.activity_rules
               .flat_map(&:formulas)
               .each_with_object({}) do |v, hash|
          hash[v.code + "_values"] = suffix_for_values(package.code, v.code, orgunit, period)
        end
      end

      def zone_subsititions
        package.zone_rules
               .flat_map(&:formulas)
               .each_with_object({}) do |formula, hash|
          hash[formula.code] = formula.code + "_for_" + period.downcase
        end
      end

      def substitions_package(orgunit)
        package.package_rules
               .flat_map(&:formulas)
               .each_with_object({}) do |formula, hash|
          hash[formula.code] = suffix_for(package.code, formula.code, orgunit, period)
        end
      end

      def activity_substitions(orgunit)
        package.activity_rules
               .flat_map(&:formulas)
               .each_with_object({}) do |v, hash|
          hash[suffix_for(package.code, v.code + "_values", orgunit, period).to_sym] = package.all_activities_codes.map do |activity_code|
            suffix_for_activity(package.code, activity_code, v.code, orgunit, period)
          end.join(", ")
        end
      end
    end
  end
end
