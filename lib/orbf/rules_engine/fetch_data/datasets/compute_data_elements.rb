
module Orbf
  module RulesEngine
    module Datasets
      class ComputeDataElements
        def initialize(project)
          @project = project
          @datasets = {}
        end

        def call
          @project.payment_rules.each do |payment_rule|
            register_payment_rules_formulas(payment_rule)
            payment_rule.packages.each do |package|
              register_package_formula(payment_rule, package)
            end
          end
          @datasets.delete_if { |_k, data_elements_ids| data_elements_ids.empty? }
          @datasets
        end

        private

        def data_set(payment_rule, frequency)
          @datasets[[payment_rule, frequency]] ||= Set.new
        end

        def register_payment_rules_formulas(payment_rule)
          payment_rule.rule.formulas.each do |formula|
            frequency = formula.frequency || payment_rule.frequency
            data_set(payment_rule, frequency)
              .merge(formula.data_elements_ids)
          end
        end

        def register_package_formula(payment_rule, package)
          package.rules.flat_map(&:formulas).each do |formula|
            frequency = formula.frequency || package.frequency
            data_set(payment_rule, frequency).merge(formula.data_elements_ids)
          end
        end
      end
    end
  end
end
