# frozen_string_literal: true

module Orbf
  module RulesEngine
    class CreatePyramid
      def initialize(dhis2_connection)
        @dhis2_connection = dhis2_connection
      end

      def call
        Orbf::RulesEngine::Pyramid.new(
          org_units:          org_units,
          org_unit_groupsets: org_unit_groupsets
        )
      end

      private

      attr_reader :dhis2_connection

      def org_units
        dhis2_connection.organisation_units
                        .fetch_paginated_data(
                          *default_params('id,displayName,path,organisationUnitGroups')
                        ).map do |ou|
          to_org_unit(ou)
        end
      end

      def to_org_unit(ou)
        Orbf::RulesEngine::OrgUnit.new(
          ext_id:        ou['id'],
          name:          ou['displayName'],
          path:          ou['path'],
          group_ext_ids: ou['organisationUnitGroups'].map { |oug| oug['id'] }
        )
      end

      def org_unit_groupsets
        dhis2_connection.organisation_unit_group_sets
                        .fetch_paginated_data(
                          *default_params('id,displayName,organisationUnitGroups')
                        ).map do |gs|
          to_org_unit_group_set(gs)
        end
      end

      def to_org_unit_group_set(gs)
        Orbf::RulesEngine::OrgUnitGroupset.new(
          ext_id:        gs['id'],
          name:          gs['displayName'],
          group_ext_ids: gs['organisationUnitGroups'].map { |oug| oug['id'] }
        )
      end

      def default_params(fields)
        [
          {
            fields:    fields,
            page_size: 10_000
          },
          raw: true
        ]
      end
    end
  end
end
