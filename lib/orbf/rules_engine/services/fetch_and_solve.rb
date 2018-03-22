# frozen_string_literal: true

module Orbf
  module RulesEngine
    class FetchAndSolve
      attr_reader :solver, :exported_values, :dhis2_values, :pyramid
      def initialize(project, orgunit_ext_id, invoicing_period, pyramid = nil)
        @orgunit_ext_id = orgunit_ext_id
        @invoicing_period = invoicing_period
        @project = project
        @dhis2_connection = ::Dhis2::Client.new(project.dhis2_params)
        @pyramid = pyramid || CreatePyramid.new(dhis2_connection).call
      end

      def call
        package_arguments = ResolveArguments.new(
          project:          project,
          pyramid:          pyramid,
          orgunit_ext_id:   orgunit_ext_id,
          invoicing_period: invoicing_period
        ).call

        @dhis2_values = FetchData.new(dhis2_connection, package_arguments.values).call

        @dhis2_values += RulesEngine::IndicatorEvaluator.new(
          project.indicators,
          dhis2_values
        ).to_dhis2_values


        package_vars = ActivityVariablesBuilder.to_variables(
          package_arguments,
          dhis2_values
        )

        @solver = SolverFactory.new(
          project,
          package_arguments,
          package_vars,
          invoicing_period
        ).new_solver
        solver.solve!

        @exported_values = RulesEngine::Dhis2ValuesPrinter.new(
          solver.variables,
          solver.solution
        ).print

        exported_values
      end

      private

      attr_reader :project, :dhis2_connection,  :orgunit_ext_id, :invoicing_period
    end
  end
end
