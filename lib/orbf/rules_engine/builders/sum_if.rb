module Orbf
  module RulesEngine
    class SumIf
      SUM_IF = "sum_if".freeze

      def self.sum_if(package, activity, orgunit)
        return true unless package.entities_aggregation_rules.any?
        package.entities_aggregation_rules
               .flat_map(&:decision_tables).each do |decision_table|
          next unless decision_table.headers(:out).include?(SUM_IF)
          input_facts = orgunit.facts
                               .merge("activity_code" => activity.activity_code)

          output_facts = decision_table.find(input_facts)

          raise "No sum_if value for this orgunit #{orgunit.id} - #{orgunit.name}" unless output_facts

          return false unless output_facts[SUM_IF] == "true"
        end
        true
      end
    end
  end
end
