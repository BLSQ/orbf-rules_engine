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
        invoices = variables.select(&:orgunit_ext_id)
                            .select(&:package)
                            .group_by { |v| [v.package, v.orgunit_ext_id, v.period, v.category_option_combo_ext_id] }
                            .map do |package_orgunit_period, vars|
          package, orgunit, period = package_orgunit_period

          activity_items = package.activities.map do |activity|
            to_activity_item(package, activity, vars, solution_as_string)
          end
          total_items = vars.select { |var| var.activity_code.nil? }
                            .each_with_object([]) do |var, array|
            next unless var.formula

            array.push(to_total_item(var, solution_as_string))
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

        payment_variables.group_by { |v| [v.payment_rule, v.orgunit_ext_id, v.period] }
                         .map do |org_unit_period, vars|
          payment_rule, org_unit, period = org_unit_period

          total_items = vars.each_with_object([]) do |var, array|
            next unless var.formula

            array.push(to_total_item(var, solution_as_string))
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
        explanations = [
          var.formula.expression,
          Tokenizer.replace_token_from_expression(
            var.expression,
            solution_as_string,
            {}
          ),
          wrap(var.expression)
        ]

        not_exported = export_explanations(explanations, var, solution_as_string)
        Orbf::RulesEngine::TotalItem.new(
          key:          var.key,
          formula:      var.formula,
          explanations: explanations,
          value:        solution[var.key],
          not_exported: not_exported
        )
      end

      def export_explanations(explanations, var, solution_as_string)
        return false unless var.exportable_variable_key

        code = var.formula.exportable_formula_code
        exportable_variable = @variables_by_key[var.exportable_variable_key]
        prefix = "export ? #{code} = "
        explanations.push(
          wrap(prefix + exportable_variable.formula.expression.to_s),
          wrap(prefix + exportable_variable.expression.to_s),
          wrap(prefix + Tokenizer.replace_token_from_expression(
            exportable_variable.expression,
            solution_as_string,
            {}
          ).to_s),
          wrap(prefix + solution[var.exportable_variable_key].to_s)
        )

        var.exportable_value(solution).nil?
      end

      def to_activity_item(package, activity, vars, solution_as_string)
        problem = {}
        substitued = {}
        values = package_codes(activity, package).each_with_object({}) do |state, hash|
          vars.select { |v| v.state == state && v.activity_code == activity.activity_code }
              .each do |activity_variable|
            value = solution[activity_variable.key]
            value = activity_variable.expression if value.nil?
            hash[state] = value
            problem[state] = activity_variable.expression
            substitued[state] = Tokenizer.replace_token_from_expression(
              activity_variable.expression,
              solution_as_string,
              {}
            )
          end
        end

        return nil if values.values.compact.none?

        Orbf::RulesEngine::ActivityItem.new(
          activity:   activity,
          solution:   values,
          problem:    problem,
          substitued: substitued,
          variables:  vars
        )
      end

      def solution_as_string
        @solution_as_string ||= begin
          solution_hash = {}
          variables.each do |var|
            solution_hash[var.key] = d_to_s(var.expression, 10)
          end
          solution.each_with_object(solution_hash) { |(k, v), hash| hash[k] = d_to_s(v, 10) }
        end
      end

      def package_codes(activity, package)
        activity.states +
          decision_codes(package) +
          level_code(package) +
          activity_formula_codes(package)
      end

      def decision_codes(package)
        package.activity_rules
               .flat_map(&:decision_tables)
               .flat_map do |decision_table|
          decision_table.headers(:in) + decision_table.headers(:out)
        end
      end

      def level_code(package)
        package.activity_rules
               .flat_map(&:formulas)
               .flat_map(&:dependencies)
               .select { |code| code.match?(/level_[0-5]/) }
      end

      def activity_formula_codes(package)
        package.activity_related_rules.flat_map(&:formulas).map(&:code)
      end

      def wrap(s, width = 120, extra = "\t")
        return "" if s.nil?

        s.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n#{extra}")
      end

      def d_to_s(decimal, number_of_decimal = 2)
        ValueFormatter.d_to_s(decimal, number_of_decimal)
      end
    end
  end
end
