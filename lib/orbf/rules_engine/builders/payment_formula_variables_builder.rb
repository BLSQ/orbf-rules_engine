# frozen_string_literal: true

module Orbf
  module RulesEngine
    class PaymentFormulaVariablesBuilder
      include VariablesBuilderSupport

      def initialize(payment_rule, arg_orgunits, invoice_period)
        @payment_rule = payment_rule
        @orgunits = arg_orgunits.flat_map(&:out_list)
        @invoice_period = invoice_period
      end

      def to_variables
        payment_rule_variables +
          temp_variable_quarterly_sum +
          temp_variable_monthly_zero_or_quarter_value
      end

      private

      attr_reader :payment_rule, :orgunits

      # if payment is quarterly and package is monthly
      # generated variables like
      #    key : quantity_amount_for_1_and_2016q1",
      #    expression : SUM(quantity_amount_for_1_and_201601,quantity_amount_for_1_and_201602,quantity_amount_for_1_and_201603)
      def temp_variable_quarterly_sum
        return [] if payment_rule.monthly?
        orgunits.each_with_object([]) do |orgunit, array|
          payment_rule.packages.select(&:monthly?).each do |package|
            package.package_rules.flat_map(&:formulas).each do |formula|
              var_dependencies = []
              PeriodIterator.each_periods(@invoice_period, package.frequency) do |period|
                var_dependencies.push suffix_for_package(package.code, formula.code, orgunit, period)
              end
              var_key = suffix_for_package(package.code, formula.code, orgunit, @invoice_period)

              array.push RulesEngine::Variable.new_payment(
                period:         @invoice_period,
                key:            var_key,
                expression:     "SUM(#{var_dependencies.join(',')})",
                state:          formula.code,
                orgunit_ext_id: orgunit.ext_id
              )
            end
          end
        end
      end

      # if payment is monthly and package is quarterly
      #
      # generated variables like these to keep everything "monthly"
      #    key : quantity_amount_for_1_and_201601",
      #    expression : 0
      # and
      #    key : quantity_amount_for_1_and_201602",
      #    expression : 0
      # and for last month
      #    key : quantity_amount_for_1_and_2016Q1",
      #    expression : 0
      #
      def temp_variable_monthly_zero_or_quarter_value
        return [] unless payment_rule.monthly?
        orgunits.each_with_object([]) do |orgunit, array|
          payment_rule.packages.select(&:quarterly?).each do |package|
            package.package_rules.flat_map(&:formulas).each do |formula|
              index = 0
              PeriodIterator.each_periods(@invoice_period, "monthly") do |period|
                var_key = suffix_for_package(package.code, formula.code, orgunit, period)
                expression = index != 2 ? "0" : suffix_for_package(package.code, formula.code, orgunit, @invoice_period)

                array.push RulesEngine::Variable.new_payment(
                  period:         period,
                  key:            var_key,
                  expression:     expression,
                  state:          formula.code,
                  orgunit_ext_id: orgunit.ext_id
                )
                index += 1
              end
            end
          end
        end
      end

      def payment_rule_variables
        substitutions = values(payment_rule)
        orgunits.each_with_object([]) do |orgunit, array|
          PeriodIterator.each_periods(@invoice_period, payment_rule.frequency) do |period|
            payment_rule.rule.formulas.each do |formula|
              expanded = RulesEngine::PaymentFormulaValuesExpander.new(
                payment_rule_code: payment_rule.code,
                formula:           formula,
                orgunit:           orgunit,
                period:            period
              ).expand_values
              substitued = Tokenizer.replace_token_from_expression(
                expanded,
                substitutions,
                orgunit_id: orgunit.ext_id,
                period:     period.downcase
              )

              array.push RulesEngine::Variable.with(
                period:         period,
                key:            suffix_for(payment_rule.code, formula.code, orgunit, period),
                expression:     substitued,
                state:          formula.code,
                type:           Orbf::RulesEngine::Variable::Types::PAYMENT_RULE,
                activity_code:  nil,
                orgunit_ext_id: orgunit.ext_id,
                formula:        formula,
                package:        nil,
                payment_rule:   payment_rule
              )
            end
          end
        end
      end

      def values(payment_rule)
        values_for_payment(payment_rule).merge(values_for_packages(payment_rule))
      end

      def values_for_payment(payment_rule)
        payment_rule.rule.formulas.each_with_object({}) do |formula, hash|
          hash[formula.code] = suffix_package_pattern(payment_rule.code, formula.code)
        end
      end

      def values_for_packages(payment_rule)
        payment_rule.packages.each_with_object({}) do |package, hash|
          package.package_rules.flat_map(&:formulas).each do |formula|
            hash[formula.code] = suffix_package_pattern(package.code, formula.code)
          end
        end
      end
    end
  end
end
