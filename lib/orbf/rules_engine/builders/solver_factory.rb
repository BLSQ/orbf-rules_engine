# frozen_string_literal: true

module Orbf
  module RulesEngine
    class SolverFactory
      PACKAGE_TYPE_ERROR = "package_arguments should be a hash[Package]=PackageArguments"
      def initialize(project, package_arguments, package_vars, invoice_period, package_builders: nil)
        @project = project
        @invoice_period = invoice_period
        @package_vars = package_vars
        @package_arguments = package_arguments
        raise PACKAGE_TYPE_ERROR unless package_arguments.is_a?(Hash)
        @package_builders = package_builders || default_package_builders
      end

      def new_solver
        Orbf::RulesEngine::Solver.new.tap do |solver|
          solver.register_variables(package_vars)
          register_packages(solver)
          register_payment_rules(solver)
        end
      end

      private

      def register_packages(solver)
        project.packages.each do |package|
          package_argument = package_arguments[package]
          next unless package_argument
          register_package(solver, package, package_argument)
        end
      end

      def register_package(solver, package, package_argument)
        PeriodIterator.each_periods(invoice_period, package.frequency) do |period|
          package_builders.each do |builder_class|
            variables = builder_class.new(package, package_argument.orgunits, period).to_variables
            solver.register_variables(variables)
          end
        end
      end

      def register_payment_rules(solver)
        project.payment_rules.each do |payment_rule|
          register_payment_rule(solver, payment_rule)
        end
      end

      def register_payment_rule(solver, payment_rule)
        orgunits = payment_rule.packages
                               .flat_map { |package| package_arguments[package]&.orgunits }
                               .compact
                               .uniq

        matching_packages = payment_rule.packages.flat_map { |package| package_arguments[package] }.compact
        return unless matching_packages.size == payment_rule.packages.size


        PeriodIterator.each_periods(invoice_period, payment_rule.frequency) do |period|
          variables = Orbf::RulesEngine::PaymentFormulaVariablesBuilder.new(
            payment_rule,
            orgunits,
            period
          ).to_variables
          solver.register_variables(variables)
        end
      end

      attr_reader :project, :package_arguments, :package_vars, :invoice_period, :package_builders

      def default_package_builders
        [
          Orbf::RulesEngine::ContractVariablesBuilder,
          Orbf::RulesEngine::ActivityConstantVariablesBuilder,
          Orbf::RulesEngine::DecisionVariablesBuilder,
          Orbf::RulesEngine::ActivityFormulaVariablesBuilder,
          Orbf::RulesEngine::PackageVariablesBuilder,
          Orbf::RulesEngine::ZoneFormulaVariablesBuilder
        ]
      end
    end
  end
end
