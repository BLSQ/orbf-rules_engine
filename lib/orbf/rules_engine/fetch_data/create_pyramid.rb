# frozen_string_literal: true

module Orbf
  module RulesEngine
    class CreatePyramid
      def initialize(dhis2_connection)
        @dhis2_connection = dhis2_connection
      end

      def call
        Orbf::RulesEngine::PyramidFactory.from_dhis2(
          org_units:          org_units,
          org_unit_groups:    org_unit_groups,
          org_unit_groupsets: org_unit_groupsets
        )
      end

      private

      attr_reader :dhis2_connection

      def org_units
        dhis2_connection.organisation_units
                        .list(
                          *default_params("id,displayName,path,organisationUnitGroups")
                        )
      end

      def org_unit_groups
        dhis2_connection.organisation_unit_groups
                        .list(
                          *default_params("id,code,shortName,displayName")
                        )
      end

      def org_unit_groupsets
        dhis2_connection.organisation_unit_group_sets
                        .list(
                          *default_params("id,code,shortName,displayName,organisationUnitGroups")
                        )
      end

      def default_params(fields)
        [
          {
            fields:    fields,
            page_size: 40_000
          }

        ]
      end
    end
  end
end
