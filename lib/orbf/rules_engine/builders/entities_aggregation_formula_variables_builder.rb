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
                variables.push(
                  Orbf::RulesEngine::Variable.new_activity_rule(
                    period:         period,
                    key:            suffix_for_activity(package.code, activity_code, suffix_raw(formula.code), orgunit, period),
                    expression:     formula.expression,
                    state:          formula.code,
                    type:           Orbf::RulesEngine::Variable::Types::CONTRACT,
                    activity_code:  activity_code,
                    orgunit_ext_id: orgunit.ext_id,
                    formula:        formula,
                    package:        package
                  )
                )
              end
            end
          end
        end
      end

      private

      attr_reader :package, :orgunits, :ref_orgunit, :period
    end
   end
end
