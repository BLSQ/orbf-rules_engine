module Orbf
  module RulesEngine
    class ActivityItem < Orbf::RulesEngine::ValueObject::Model(:activity, :solution, :problem, :substitued, :variables)

      def after_init
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
        val == false || val == 0
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

    class TotalItem < Orbf::RulesEngine::ValueObject::Model(:key, :formula, :explanations, :value, :not_exported)
      def not_exported?
        @not_exported
      end

      def inspect
        "TotalItem(#{formula.code} #{explanations})"
      end
    end

    class Invoice < Orbf::RulesEngine::ValueObject::Model(:kind, :period, :orgunit_ext_id, :package, :payment_rule, :activity_items, :total_items)

      def code
        package&.code || payment_rule&.code
      end

      def inspect
        "Invoice(#{kind} #{period} #{orgunit_ext_id} #{code})"
      end

      def headers
        activity_items.flat_map(&:solution).sort_by(&:size).last.keys
      end
    end
  end
end
