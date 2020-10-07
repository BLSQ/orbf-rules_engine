# frozen_string_literal: true

module Orbf
  module RulesEngine
    class FetchAndSolve
      attr_reader :solver, :exported_values, :dhis2_values, :pyramid

      def initialize(project, orgunit_ext_id, invoicing_period, pyramid: nil, mock_values: nil)
        @orgunit_ext_id = orgunit_ext_id
        @invoicing_period = invoicing_period
        @project = project

        @pyramid = pyramid || CreatePyramid.new(dhis2_connection).call
        @mock_values = mock_values
      end

      def call
        package_arguments = resolve_package_arguments

        @dhis2_values = fetch_data(package_arguments)

        @solver = new_solver(package_arguments)
        solver.solve!

        @exported_values = RulesEngine::Dhis2ValuesPrinter.new(
          solver.variables,
          solver.solution,
          project.default_combos_ext_ids
        ).print

        exported_values
      end

      def contract_service
        return nil unless project.contract_settings

        @contract_service ||= ::Orbf::RulesEngine::ContractService.new(
          program_id:            project.contract_settings[:program_id],
          all_event_sql_view_id: project.contract_settings[:all_event_sql_view_id],
          dhis2_connection:      dhis2_connection,
          calendar:              project.calendar
        )
      end

      private

      attr_reader :project, :dhis2_connection, :orgunit_ext_id, :invoicing_period

      def dhis2_connection
        @dhis2_connection ||= ::Dhis2::Client.new(project.dhis2_params)
      end

      def resolve_package_arguments
        ResolveArguments.new(
          project:          project,
          pyramid:          pyramid,
          orgunit_ext_id:   orgunit_ext_id,
          invoicing_period: invoicing_period,
          contract_service: contract_service
        ).call
      end

      def new_solver(package_arguments)
        package_vars = ActivityVariablesBuilder.to_variables(
          package_arguments,
          dhis2_values
        )

        if package_arguments.keys.any?(&:loop_over_combo)
          package_vars += ActivityComboVariablesBuilder.to_variables(
            package_arguments,
            dhis2_values
          )
        end

        SolverFactory.new(
          project,
          package_arguments,
          package_vars,
          invoicing_period
        ).new_solver
      end

      def fetch_data(package_arguments)
        return [] if package_arguments.empty?

        values = @mock_values || FetchData.new(
          dhis2_connection:  dhis2_connection,
          package_arguments: package_arguments.values,
          read_through_deg:  project.read_through_deg
        ).call

        values += RulesEngine::IndicatorEvaluator.new(
          project.indicators,
          values
        ).to_dhis2_values

        values
      end
    end
  end
end
