# frozen_string_literal: true

module Orbf
  module RulesEngine
    class ZoneFormulaVariablesBuilder
      include VariablesBuilderSupport

      def initialize(package, orgunits, period)
        @package = package
        @ref_orgunit = orgunits.ref_orgunit
        @secondary_orgunits = orgunits.secondary_orgunits
        @period = period
      end

      def to_variables
        zone_orgs_formula_variables
      end

      private

      attr_reader :orgunits, :package, :period, :ref_orgunit, :secondary_orgunits

      def zone_orgs_formula_variables
        substitutions = values_substitutions

        package.zone_rules.flat_map(&:formulas).map do |zone_formula|
          formatted = format(zone_formula.expression, substitutions)
          formatted = Tokenizer.replace_token_from_expression(
            formatted,
            zone_substitions,
            {}
          )
          Orbf::RulesEngine::Variable.with(
            period:         period,
            key:            zone_formula.code + "_for_" + period.downcase,
            expression:     formatted,
            state:          zone_formula.code,
            type:           Orbf::RulesEngine::Variable::Types::ZONE_RULE,
            activity_code:  nil,
            orgunit_ext_id: ref_orgunit.ext_id,
            formula:        zone_formula,
            package:        package,
            payment_rule:   nil
          )
        end
      end

      def zone_substitions
        package.zone_rules.flat_map(&:formulas).each_with_object({}) do |zone_formula, hash|
          hash[zone_formula.code] = zone_formula.code + "_for_" + period.downcase
        end
      end

      def values_substitutions
        package.package_rules
               .flat_map(&:formulas)
               .each_with_object({}) do |package_formula, hash|
          values = secondary_orgunits.map do |orgunit|
            suffix_for(package.code, package_formula.code, orgunit, period)
          end
          hash["#{package_formula.code}_values".to_sym] = values.join(",")
        end
      end
    end
  end
end
