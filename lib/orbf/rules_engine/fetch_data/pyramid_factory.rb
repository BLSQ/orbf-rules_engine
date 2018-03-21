module Orbf
  module RulesEngine
    class PyramidFactory

      class << self
        def from_dhis2(org_units:, org_unit_groups:, org_unit_groupsets:)
            Orbf::RulesEngine::Pyramid.new(
                org_units:          org_units.map { |ou| to_org_unit(ou) },
                org_unit_groups:    org_unit_groups.map { |group| to_org_unit_groups(group) },
                org_unit_groupsets: org_unit_groupsets.map { |gs| to_org_unit_group_set(gs) }
            )
        end

        private

        def to_org_unit(ou)
            Orbf::RulesEngine::OrgUnit.new(
                ext_id:        ou["id"],
                name:          ou["displayName"],
                path:          ou["path"],
                group_ext_ids: ou["organisationUnitGroups"].map { |oug| oug["id"] }
            )
        end

        def to_org_unit_groups(group)
            Orbf::RulesEngine::OrgUnitGroup.new(
                ext_id: group["id"],
                name:   group["displayName"],
                code:   to_code(group)
            )
        end

        def to_org_unit_group_set(gs)
            Orbf::RulesEngine::OrgUnitGroupset.new(
                ext_id:        gs["id"],
                name:          gs["displayName"],
                code:          to_code(gs),
                group_ext_ids: gs["organisationUnitGroups"].map { |oug| oug["id"] }
            )
        end

        def to_code(dhis2_ressource)
            code = dhis2_ressource["code"] || dhis2_ressource["shortName"] || dhis2_ressource["displayName"]
            Codifier.codify(code)
        end
      end
    end
  end
end
