module Orbf
  module RulesEngine
    class SumIf
      SUM_IF = "sum_if".freeze

      def initialize(package, activity, orgunit)
        @package = package
        @activity = activity
        @orgunit = orgunit
      end

      def sum_if
        decision_tables.each do |decision_table|
          output_facts = decision_table.find(input_facts)
          expect_outputs(input_facts, output_facts)
          return false unless output_facts[SUM_IF] == "true"
        end
        true
      end

      class << self
        def org_units(orgunits, package, activity)
          orgunits.each_with_object([]) do |orgunit, array|
            next unless SumIf.new(package, activity, orgunit).sum_if
            array.push orgunit
          end
        end
      end

      private

      attr_reader :package, :activity, :orgunit

      def expect_outputs(input_facts, output_facts)
        raise "No sum_if value for this orgunit #{orgunit.ext_id} - #{orgunit.name} (#{input_facts})" unless output_facts
      end

      def input_facts
        orgunit.facts.merge("activity_code" => activity.activity_code)
      end

      def decision_tables
        return [] unless package.entities_aggregation_rules.any?
        package.entities_aggregation_rules
               .flat_map(&:decision_tables)
               .select { |decision_table| decision_table.headers(:out).include?(SUM_IF) }
      end
    end
  end
end
