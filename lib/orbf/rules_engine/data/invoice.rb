module Orbf
  module RulesEngine
    class ActivityItem < Orbf::RulesEngine::ValueObject
      attributes :activity, :solution, :problem, :substitued, :variables
      attr_reader :activity, :solution, :problem, :substitued, :variables

      def initialize(hash)
        @activity = hash[:activity]
        @solution = hash[:solution]
        @problem = hash[:problem]
        @substitued = hash[:substitued]
        @variables = hash[:variables]
        @indexed_variables = variables.index_by { |v| [v.state, v.activity_code] }
        freeze
      end

      def variable(code)
        @indexed_variables[[code, activity.activity_code]]
      end

      def not_exported?(code)
        var = variable(code)
        return false unless var&.formula&.exportable_formula_code

        val = solution[var.formula.exportable_formula_code]
        [false, 0].include?(val)
      end

      def input?(code)
        varr = variable(code)
        varr.state == code && varr.formula.nil?
      end

      def output?(code)
        variable(code)&.exportable?
      end

      def inspect
        "ActivityItem(#{activity.activity_code} #{solution})"
      end
    end

    class TotalItem < Orbf::RulesEngine::ValueObject
      attributes :key, :formula, :explanations, :value, :not_exported
      attr_reader :key, :formula, :explanations, :value, :not_exported

      def initialize(hash)
        @key = hash[:key]
        @formula = hash[:formula]
        @explanations = hash[:explanations]
        @value = hash[:value]
        @not_exported = hash[:not_exported]
        freeze
      end

      def not_exported?
        @not_exported
      end

      def inspect
        "TotalItem(#{formula.code} #{explanations})"
      end
    end

    class Invoice < Orbf::RulesEngine::ValueObject
      attributes :kind, :period, :orgunit_ext_id, :package, :payment_rule, :activity_items, :total_items, :coc_ext_id

      def code
        package&.code || payment_rule&.code
      end

      def inspect
        "Invoice(#{kind} #{period} #{orgunit_ext_id} #{code} #{coc_ext_id})"
      end

      def headers
        activity_items.flat_map(&:solution).sort_by(&:size).last.keys
      end
    end
  end
end
