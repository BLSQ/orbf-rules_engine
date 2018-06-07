# frozen_string_literal: true

module Orbf
  module RulesEngine
    class PackageDecisionVariablesBuilder
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
        decision_tables = package.package_rules.flat_map(&:decision_tables)
        return [] if decision_tables.none?
        decision_tables.each_with_object([]) do |decision_table, array|
          variables = decision_variables(decision_table)
          array.push(*variables)
        end
      end

      private

      attr_reader :package, :orgunits, :period

      def decision_variables(decision_table)
        orgunits.each_with_object([]) do |orgunit, array|
          input_facts = orgunit.facts
          output_facts = decision_table.find(input_facts)
          unless output_facts
            Orbf::RulesEngine::Log.call "WARN : no facts for #{orgunit} #{input_facts} in #{decision_table}"
            next
          end
          output_facts.each do |code, value|
            array.push(build_variable(orgunit, code, value))
          end
        end
      end

      def build_variable(orgunit, code, value)
        Orbf::RulesEngine::Variable.new_package_decision_table(
          period:         period,
          key:            suffix_for_package(package.code, code, orgunit, period),
          expression:     value,
          state:          code,
          orgunit_ext_id: orgunit.ext_id,
          package:        package
        )
      end
    end
  end
end
