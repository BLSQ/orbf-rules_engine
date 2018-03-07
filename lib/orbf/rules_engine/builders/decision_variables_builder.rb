# frozen_string_literal: true

module Orbf
  module RulesEngine
    class DecisionVariablesBuilder
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
        decision_tables = package.activity_rules.flat_map(&:decision_tables)
        return [] if decision_tables.none?

        decision_tables.each_with_object([]) do |decision_table, array|
          variables = decision_variables(decision_table)
          array.push(*variables)
        end
      end

      private

      attr_reader :package, :orgunits, :period

      def decision_variables(decision_table)
        package.all_activities_codes
               .each_with_object([]) do |activity_code, array|
          orgunits.each do |orgunit|
            input_facts = orgunit.facts
                                 .merge("activity_code" => activity_code)

            output_facts = decision_table.find(input_facts)
            next unless output_facts
            output_facts.each do |code, value|
              array.push(build_variable(orgunit, activity_code, code, value))
            end
          end
        end
      end

      def build_variable(orgunit, activity_code, code, value)
        Orbf::RulesEngine::Variable.with(
          period:         period,
          key:            suffix_for_activity(
            package.code,
            activity_code,
            code,
            orgunit,
            period
          ),
          expression:     value,
          state:          code,
          type:           :activity_rule_decision,
          activity_code:  activity_code,
          orgunit_ext_id: orgunit.ext_id,
          formula:        nil,
          package:        package
        )
      end
    end
  end
end
