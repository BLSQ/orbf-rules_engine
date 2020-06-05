# frozen_string_literal: true

module Orbf
  module RulesEngine
    class ContractOrgunitsResolver
      def initialize(package, pyramid, main_orgunit, contract_service, period)
        @package = package
        @pyramid = pyramid
        @main_orgunit = main_orgunit
        @contract_service = contract_service
        @main_orgunit_contract = contract_service.for(main_orgunit.ext_id, period)
        @period = period
      end

      def call
        selected_orgunits = if package.subcontract? then handle_subcontract
                            elsif package.single?      then handle_single
                            elsif package.zone?        then handle_zone
                            else raise("unhandled package kind: #{package.kind}")
        end
        OrgUnits.new(orgunits: selected_orgunits, package: package)
      end

      private

      attr_reader :package, :pyramid, :main_orgunit

      def handle_zone
        if package.target_org_unit_group_ext_ids.any?
          handle_target_org_units
        else
          handle_subcontract(include_main_orgunit: package.include_main_orgunit?)
        end
      end

      def handle_single
        return [] unless @main_orgunit_contract
        return [] unless within_package_groups?

        [main_orgunit]
      end

      def handle_target_org_units
        target_codes = pyramid.groups(package.target_org_unit_group_ext_ids).map(&:code)
        target_contracts = @contract_service.for_groups(target_codes, @period)
        org_units_set = pyramid.org_units_for(target_contracts.map(&:org_unit_id))
        org_units_set = org_units_set.keep_if { |orgunit| orgunit.path.start_with?(main_orgunit.path) }
        org_units_set.delete(main_orgunit)
        org_units_set.to_a.unshift(main_orgunit)
      end

      def handle_subcontract(include_main_orgunit: false)
        return [] unless within_package_groups?

        subcontracts = @contract_service.for_subcontract(main_orgunit.ext_id, @period)
        org_units_set = pyramid.org_units_for(subcontracts.map(&:org_unit_id))
        org_units_set_size = org_units_set.size
        org_units_set.delete(main_orgunit) unless include_main_orgunit
        orgunits = org_units_set.to_a.unshift(main_orgunit)

        if include_main_orgunit && org_units_set_size == 0
          # make sure if main orgunit is alone, they appear twice,
          # once as main and once as target
          orgunits = orgunits.push(main_orgunit)
        end
        orgunits
      end

      def groupset
        pyramid.groupset(package.groupset_ext_id)
      end

      def within_package_groups?
        if package.matching_groupset_ext_ids.empty?
          package_codes = pyramid.groups(package.main_org_unit_group_ext_ids).map(&:code)
          orgunit_codes = @main_orgunit_contract.codes

          return (orgunit_codes & package_codes).present?
        end

        package_groups_by_groupset = package.main_org_unit_group_ext_ids.group_by do |group_id|
          pyramid.org_unit_groupsets.detect do |group_set|
            groupset_match = package.matching_groupset_ext_ids.include?(group_set.ext_id)
            group_in_groupset = group_set.group_ext_ids.include?(group_id)
            (groupset_match && group_in_groupset)
          end
        end

        non_matching = package_groups_by_groupset.reject do |_group_set, package_group_ext_ids|
          package_groups_code = pyramid.groups(package_group_ext_ids).map(&:code)
          (@main_orgunit_contract.codes & package_groups_code).present?
        end
        non_matching.empty?
      end
    end
  end
end
