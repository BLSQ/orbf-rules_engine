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
        if package.subcontract? then handle_subcontract
        elsif package.single?      then handle_single
        elsif package.zone?        then handle_zone
        else raise("unhandled package kind: #{package.kind}")
        end
      end

      private

      attr_reader :package, :pyramid, :main_orgunit

      def handle_zone
        handle_subcontract
      end

      def handle_single
        return [] unless within_package_groups?
        [main_orgunit]
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
        (main_orgunit.group_ext_ids & package.org_unit_group_ext_ids).present?
      end
    end
  end
end
