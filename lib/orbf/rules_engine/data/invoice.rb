module Orbf
  module RulesEngine
    class ActivityItem < Orbf::RulesEngine::ValueObject
      attributes :activity, :solution, :problem, :variables

      def variable(code)
        variables.detect { |v| v.state == code && v.activity_code == activity.activity_code }
      end

      def input?(code)
       var = variable(code)
       return var.state == code && var.formula.nil?
      end

      def output?(code)
        variable(code)&.exportable?
      end

      def inspect
        "ActivityItem(#{activity.activity_code} #{solution})"
      end
    end
    class TotalItem < Orbf::RulesEngine::ValueObject
      attributes :formula, :explanations, :value

      def inspect
        "TotalItem(#{formula.code} #{explanations})"
      end
    end
    class Invoice < Orbf::RulesEngine::ValueObject
      attributes :kind, :period, :orgunit_ext_id, :package, :payment_rule, :activity_items, :total_items

      def code
        package&.code || payment_rule&.code
      end

      def inspect
        "Invoice(#{kind} #{period} #{orgunit_ext_id} #{code})"
      end

      def headers
        activity_items.first.solution.keys
      end
    end
  end
end
