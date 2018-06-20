
module Orbf
  module RulesEngine
    class ComputeDataElements
      class DataSet
        attr_reader :formula_mappings

        def initialize(payment_rule, frequency)
          @payment_rule = payment_rule
          @frequency = frequency
          @formula_mappings = []
        end

        def add_formula_mapping(formula_mapping)
          @formula_mappings.push(formula_mapping)
        end

        def data_element_ids
          @formula_mappings.map(&:external_reference).uniq
        end

        def inspect
          "#{@payment_rule.code}(frequency=#{@frequency} data_elements=#{data_element_ids})"
        end
      end

      class DataSetRegistry
        attr_reader :datasets

        def initialize
          @datasets = {}
        end

        def data_set(payment_rule, frequency)
          @datasets[[payment_rule, frequency]] ||= Meta::DataSet.new(payment_rule, frequency)
        end

        def compact
          @datasets.delete_if { |_k, dataset| dataset.formula_mappings.empty? }
          self
        end
      end

      class SynchroniseDatasets
        def initialize(project)
          @project = project
          @dataset_registry = DataSetRegistry.new
        end

        def call
          @project.payment_rules.each do |payment_rule|
            register_payment_rules_formulas(payment_rule)
            payment_rule.packages.each do |package|
              register_package_formula(payment_rule, package)
            end
          end

          dataset_registry.compact
        end

        private

        attr_reader :dataset_registry

        def register_payment_rules_formulas(payment_rule)
          payment_rule.rule.formulas.each do |formula|
            next unless formula.formula_mappings

            frequency = formula.frequency || payment_rule.frequency
            formula.formula_mappings.each do |formula_mapping|
              dataset_registry.data_set(payment_rule, frequency)
                              .add_formula_mapping(formula_mapping)
            end
          end
        end

        def register_package_formula(payment_rule, package)
          package.rules.flat_map(&:formulas).each do |formula|
            next unless formula.formula_mappings
            frequency = formula.frequency || package.frequency
            formula.formula_mappings.each do |formula_mapping|
              dataset_registry.data_set(payment_rule, frequency)
                              .add_formula_mapping(formula_mapping)
            end
          end
        end
      end
    end
  end
end
