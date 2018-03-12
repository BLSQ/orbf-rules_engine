# frozen_string_literal: true

module Orbf
  module RulesEngine
    class FetchAndSolve
      def initialize(project, orgunit_ext_id, invoicing_period)
        @orgunit_ext_id = orgunit_ext_id
        @invoicing_period = invoicing_period
        @project = project
        @dhis2_connection = ::Dhis2::Client.new(project.dhis2_params) # ?

        # should reuse snapshots from db, "receiving it" via the constructor is perhaps better
        @pyramid = CreatePyramid.new(dhis2_connection).call
      end

      def call
        package_arguments = ResolveArguments.new(
          project:          project,
          pyramid:          pyramid,
          orgunit_ext_id:   orgunit_ext_id,
          invoicing_period: invoicing_period
        ).call

        dhis2_values = FetchData.new(dhis2_connection, package_arguments.values).call

        # TODO: I think it's the other branch
        dhis2_values += RulesEngine::IndicatorEvaluator.new(project, dhis2_values).call

        # orgs from package arguments ?

        package_vars = ActivityVariablesBuilder.to_variables(package_arguments, dhis2_values)
        # adapt solver factory to receive package_arguments and replace filtered_packages with it
        solver = SolverFactory.new(
          project,
          package_arguments,
          package_vars,
          invoicing_period
        ).new_solver
        solver.solve!

        RulesEngine::InvoicePrinter.new(solver.variables, solver.solution).print

        exported_values = RulesEngine::Dhis2ValuesPrinter.new(solver.variables, solver.solution).print

        # TODO: create an entry in dhis2_logs and push to dhis2
        # dhis2_connection.data_value_sets.bulk_create(exported_values) if exported_values.any?

        exported_values
      end

      private

      attr_reader :project, :dhis2_connection, :pyramid, :orgunit_ext_id, :invoicing_period
    end
  end
end
