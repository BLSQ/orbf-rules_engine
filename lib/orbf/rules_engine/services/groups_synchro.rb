module Orbf
  module RulesEngine
    class IncoherentProgramGroupError < StandardError
    end
    class GroupsSynchro
      attr_reader :contract_service

      def initialize(contract_service)
        @contract_service = contract_service
        @groups = {}
      end

      def synchronise(period)
        contracts_by_orgunit = contract_service.find_all.group_by(&:org_unit_id)

        contracts_by_orgunit.each do |(org_unit_id, contracts)|
          contract_for_period = contracts.find { |contract| contract.match_period?(period) }
          if contract_for_period.nil?
            # find nearest contract without really a preference ?
            contract_for_period = contracts.min_by { |contract| contract.distance(period) }
          end

          toggle_groups_membership(contract_for_period, org_unit_id)
          toggle_contracted_non_contracted_membership(contract_for_period, org_unit_id, period)
        end

        update_all_groups
      end

      private

      def toggle_groups_membership(contract_for_period, org_unit_id)
        # for each data element, add to need group and remove other groups
        @contract_service.group_based_data_elements.each do |de|
          de["option_set"]["options"].each do |option|
            ou_group = find_group(option["code"])
            should_add = option["code"] == contract_for_period.field_values[de["code"]]
            if should_add
              add_to(ou_group, org_unit_id)
            else
              remove_from(ou_group, org_unit_id)
            end
          end
        end
      end

      def toggle_contracted_non_contracted_membership(contract_for_period, org_unit_id, period)
        # if the contract match the period, add to "contracted" group
        # else to "non-contracted" one
        ou_contracted_group = find_group("contracted")
        ou_non_contracted_group = find_group("non-contracted")

        if contract_for_period.match_period?(period)
          add_to(ou_contracted_group, org_unit_id)
          remove_from(ou_non_contracted_group, org_unit_id)
        else
          add_to(ou_non_contracted_group, org_unit_id)
          remove_from(ou_contracted_group, org_unit_id)
        end
      end

      def add_to(ou_group, org_unit_id)
        org_unit = ou_group.organisation_units.find { |ou| ou["id"] == org_unit_id }

        if org_unit.nil?
          ou_group["organisation_units"].append({ "id" => org_unit_id })
          puts "added #{org_unit_id} to #{ou_group['code']}"
        end
      end

      def remove_from(ou_group, org_unit_id)
        size_before = ou_group.organisation_units.size
        ou_group.organisation_units = ou_group.organisation_units.reject { |ou| ou["id"] == org_unit_id }
        if size_before > ou_group["organisation_units"].size
          puts "removed #{org_unit_id} to #{ou_group.code}"
        end
      end

      def dhis2
        @dhis2 ||= contract_service.dhis2_connection
      end

      def find_group(code)
        @groups[code] ||= begin
          ou_groups = dhis2.organisation_unit_groups.list(filter: "code:eq:#{code}", fields: :all)

          if ou_groups.empty?
            message = "no organisation unit group with code #{code} "\
                      "but assumed by the program #{@contract_service.program.name} (#{@contract_service.program.id})"
            raise IncoherentProgramGroupError, message
          end

          ou_groups[0]
        end
      end

      def update_all_groups
        puts(@groups.keys.join(",") + " groups")
        display_groups_stats("before")
        @groups.each do |(_code, group)|
          group.update
        end
        display_groups_stats("after")
      end

      def display_groups_stats(message)
        stats = dhis2.get("organisationUnitGroupSets.json?fields=id,name,code,organisationUnitGroups[id,name,code,organisationUnits~size]")
        puts ("*** Groups stats #{message} :" + JSON.pretty_generate(stats))
      end
    end
  end
end
