# frozen_string_literal: true

module Orbf
  module RulesEngine
    class ZoneActivityFormulaVariablesBuilder
      include VariablesBuilderSupport

      def initialize(package, orgunits, period)
        @package = package
        @ref_orgunit = orgunits.ref_orgunit
        @secondary_orgunits = orgunits.secondary_orgunits
        @period = period
      end

      # Gets called by SolverFactory to
      def to_variables
        return [] unless package.zone_activity_rules.any?

        zone_activity_formula_variables
      end

      private

      attr_reader :orgunits, :package, :period, :ref_orgunit, :secondary_orgunits

      # Returns an array of Orbf::RulesEngine::Variable
      def zone_activity_formula_variables
        org_units_count = secondary_orgunits.size.to_s
        org_units_key = Orbf::RulesEngine::ContractVariablesBuilder::ORG_UNITS_COUNT

        package.all_activities_codes.each_with_object([]) do |activity_code, array|
          package.zone_activity_rules.each do |rule|
            rule.formulas.each do |formula|
              expansions = activity_formula_expansions(formula, activity_code)
              substitutions = all_zone_referenced_substitutions(formula, activity_code)
              substitutions[org_units_key] = org_units_count

              # Expand %{vars}
              expression = formula.expression % expansions

              # Substitute direct_vars
              expression = Tokenizer.replace_token_from_expression(expression, substitutions, {})

              array.push(build_variable(activity_code, formula, expression))
            end
          end
        end
      end

      # Loop over all activity rules and make the combined _values
      # method for their formulas , but only ones that are used in the
      # passed in formula.
      #
      # Simplified example:
      #
      #      ActivityRule A with code 'a', ActivityRule B with code 'b'
      #
      # Would return:
      #
      #       {
      #         a_values: "a_for_orgunit_1, a_for_orgunit_1",
      #         b_values: "b_for_orgunit_1, b_for_orgunit_2"
      #       }
      #
      # Returns a hash
      def activity_formula_expansions(formula, activity_code)
        package.activity_rules
          .flat_map(&:formulas)
          .each_with_object({}) do |activity_formula, result|
          key = activity_formula.code + "_values"
          next unless formula.expression.include? key

          keys = secondary_orgunits.map do |secondary_orgunit|
            r = [package.code, activity_code, activity_formula.code, secondary_orgunit.ext_id, period]
            suffix_for_id_activity(package.code, activity_code, activity_formula.code, secondary_orgunit.ext_id, period)
          end
          result[key.to_sym] = keys.join(", ")
        end
      end

      # Loop over all zone activity formulas and expand them, but only
      # ones that are used in the passed in formula
      #
      # ZoneActivityRule A with code 'a'
      #
      # Would return
      #
      #       {
      #         a: "my_expanded_value_for_a"
      #       }
      #
      # Returns a hash
      def all_zone_referenced_substitutions(formula, activity_code)
        package.zone_activity_rules
          .flat_map(&:formulas)
          .each_with_object({}) do |activity_formula, result|
          key = activity_formula.code

          next unless formula.expression.include? key
          result[key] = suffix_for_id_activity(package.code, activity_code,
                                               activity_formula.code,
                                               ref_orgunit.ext_id,
                                               period)
        end
      end

      def build_variable(activity_code, formula, expression)
        Orbf::RulesEngine::Variable.new_zone_activity_rule(
          period:                  period,
          key:                     variable_key(ref_orgunit, activity_code, formula),
          expression:              expression,
          state:                   formula.code,
          activity_code:           activity_code,
          orgunit_ext_id:          ref_orgunit.ext_id,
          formula:                 formula,
          package:                 package,
          exportable_variable_key: exportable_variable_key(ref_orgunit, activity_code, formula)
        )
      end

      def variable_key(orgunit, activity_code, formula)
        suffix_for_activity(
          package.code,
          activity_code,
          formula.code,
          orgunit,
          period
        )
      end

      def exportable_variable_key(orgunit, activity_code, formula)
        return unless formula.exportable_formula_code

        suffix_for_activity(
          package.code,
          activity_code,
          formula.exportable_formula_code,
          orgunit,
          period
        )
      end
    end
  end
end
