module Orbf
  module RulesEngine
    class InvoicePrinter
      attr_reader :variables, :solution

      def initialize(variables, solution)
        @variables = variables
        @solution = solution
        @variables_by_key = @variables.group_by(&:key)
                                      .each_with_object({}) { |(k, v), hash| hash[k] = v.first }
      end

      def print
        solution_as_string = solution.each_with_object({}) { |(k, v), hash| hash[k] = d_to_s(v, 10) }
        invoices = variables.select(&:orgunit_ext_id).select(&:package).group_by { |v| [v.package, v.orgunit_ext_id, v.period] }
                            .map do |package_orgunit_period, vars|
          package, orgunit, period = package_orgunit_period

          activity_items = package.activities.map do |activity|
            to_activity_item(package, activity, vars)
          end
          total_items = vars.select { |var| var.activity_code.nil? }.map do |var|
            to_total_item(var, solution_as_string)
          end

          Orbf::RulesEngine::Invoice.new(
            kind:           "package",
            period:         period,
            orgunit_ext_id: orgunit,
            package:        package,
            payment_rule:   nil,
            activity_items: activity_items.compact,
            total_items:    total_items
          )
        end
        (invoices + print_payments(solution_as_string)).compact
      end

      def print_payments(solution_as_string)
        payment_variables = variables.select(&:payment_rule_type?)
                                     .select(&:formula)
        puts "no payment" if payment_variables.none?
        payment_variables.group_by { |v| [v.payment_rule, v.orgunit_ext_id, v.period] }
                         .map do |org_unit_period, vars|
          payment_rule, org_unit, period = org_unit_period
          # Orbf::RulesEngine::Log.call "---------- Payments for #{payment_rule.code} #{org_unit} #{period}"
          total_items = vars.each do |var|
            to_total_item(var, solution_as_string)
          end

          Orbf::RulesEngine::Invoice.new(
            kind:           "payment_rule",
            period:         period,
            orgunit_ext_id: org_unit,
            package:        nil,
            payment_rule:   payment_rule,
            activity_items: [],
            total_items:    total_items
          )
        end
      end

      def to_total_item(var, solution_as_string)
        Orbf::RulesEngine::TotalItem.new(
          formula:      var.formula,
          explanations: [
            var.formula.expression,
            Tokenizer.replace_token_from_expression(
              var.expression,
              solution_as_string,
              {}
            ),
            wrap(var.expression)
          ],
          value:        solution[var.key]
        )
      end

      def to_activity_item(package, activity, vars)
        codes = (activity.states + package.activity_rules.flat_map(&:formulas).map(&:code))
        problem = {}

        values = codes.each_with_object({}) do |state, hash|
          vars.select { |v| v.state == state && v.activity_code == activity.activity_code }
              .each do |activity_variable|
            hash[state] = solution[activity_variable.key] || activity_variable.expression
            problem[state] = activity_variable.expression
          end
        end
        return nil if values.values.compact.none?

        Orbf::RulesEngine::ActivityItem.new(
          activity: activity,
          solution: values,
          problem:  problem
        )
      end

      def wrap(s, width = 120, extra = "\t\t")
        s.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n#{extra}")
      end

      def d_to_s(decimal, number_of_decimal = 2)
        return decimal.to_i.to_s if number_of_decimal > 2 && decimal.to_i == decimal.to_f
        return decimal.to_f.to_s if number_of_decimal > 2
        return format("%.#{number_of_decimal}f", decimal) if decimal.is_a? Numeric
        decimal
      end
    end
  end
end
