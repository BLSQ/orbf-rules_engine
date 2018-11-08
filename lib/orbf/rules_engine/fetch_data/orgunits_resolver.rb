# frozen_string_literal: true

module Orbf
  module RulesEngine
    class OrgunitsResolver
      def initialize(package, pyramid, main_orgunit)
        @package = package
        @pyramid = pyramid
        @main_orgunit = main_orgunit
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
        handle_subcontract
      end
      end

      def handle_single
        return [] unless within_package_groups?
        [main_orgunit]
      end

      def handle_target_org_units
        org_units_set = pyramid.orgunits_in_groups(package.target_org_unit_group_ext_ids)
        org_units_set = org_units_set.keep_if { |orgunit| orgunit.path.start_with?(main_orgunit.path) }
        org_units_set.delete(main_orgunit)
        org_units_set.to_a.unshift(main_orgunit)
      end

      def handle_subcontract
        return [] unless within_package_groups?
        common_groups_with_group_set = main_orgunit.group_ext_ids & groupset.group_ext_ids
        org_units_set = pyramid.orgunits_in_groups(common_groups_with_group_set)
        org_units_set.delete(main_orgunit)
        org_units_set.to_a.unshift(main_orgunit)
      end

      def groupset
        pyramid.groupset(package.groupset_ext_id)
      end

      def within_package_groups?
        if package.matching_groupset_ext_ids.empty?
          return (main_orgunit.group_ext_ids & package.main_org_unit_group_ext_ids).present?
        end

        package_groups_by_groupset = package.main_org_unit_group_ext_ids.group_by do |group_id|
          pyramid.org_unit_groupsets.detect do |group_set|
            groupset_match = package.matching_groupset_ext_ids.include?(group_set.ext_id)
            group_in_groupset = group_set.group_ext_ids.include?(group_id)
            (groupset_match && group_in_groupset)
          end
        end

        non_matching = package_groups_by_groupset.reject do |_group_set, package_group_ext_ids|
          (main_orgunit.group_ext_ids & package_group_ext_ids).present?
        end
        non_matching.empty?
      end
    end
  end
end
