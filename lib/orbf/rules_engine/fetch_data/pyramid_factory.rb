module Orbf
  module RulesEngine
    class PyramidFactory
      class << self
        def from_snapshot(org_units:, org_unit_groups:, org_unit_groupsets:)
          Orbf::RulesEngine::Pyramid.new(
            org_units:          org_units.map { |ou| to_org_unit(ou["table"]) },
            org_unit_groups:    org_unit_groups.map { |group| to_org_unit_group(group["table"]) },
            org_unit_groupsets: org_unit_groupsets.map { |gs| to_org_unit_group_set(gs["table"]) }
          )
        end

        def from_dhis2(org_units:, org_unit_groups:, org_unit_groupsets:)
          Orbf::RulesEngine::Pyramid.new(
            org_units:          org_units.map { |ou| to_org_unit(ou) },
            org_unit_groups:    org_unit_groups.map { |group| to_org_unit_group(group) },
            org_unit_groupsets: org_unit_groupsets.map { |gs| to_org_unit_group_set(gs) }
          )
        end

        private

        def to_org_unit(ou)
          Orbf::RulesEngine::OrgUnit.new(
            ext_id:        ou["id"],
            name:          display_name(ou),
            path:          ou["path"],
            group_ext_ids: organistation_unit_groups_ids(ou)
          )
        end

        def to_org_unit_group(group)
          Orbf::RulesEngine::OrgUnitGroup.new(
            ext_id: group["id"],
            name:   display_name(group),
            code:   to_code(group)
          )
        end

        def to_org_unit_group_set(gs)
          Orbf::RulesEngine::OrgUnitGroupset.new(
            ext_id:        gs["id"],
            name:          display_name(gs),
            code:          to_code(gs),
            group_ext_ids: organistation_unit_groups_ids(gs)
          )
        end

        def display_name(dhis2_resource)
          dhis2_resource["displayName"] || dhis2_resource["display_name"]
        end

        def short_name(dhis2_resource)
          dhis2_resource["shortName"] || dhis2_resource["short_name"]
        end

        def organistation_unit_groups_ids(dhis2_resource)
          organistation_unit_groups(dhis2_resource).map { |oug| oug["id"] }
        end

        def organistation_unit_groups(dhis2_resource)
          dhis2_resource["organisationUnitGroups"] ||
            dhis2_resource["organisation_unit_groups"] ||
            []
        end

        def to_code(dhis2_ressource)
          code = dhis2_ressource["code"] || short_name(dhis2_ressource) || display_name(dhis2_ressource)
          Codifier.codify(code)
        end
      end
    end
  end
end
