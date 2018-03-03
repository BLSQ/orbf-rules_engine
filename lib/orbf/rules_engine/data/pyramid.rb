# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Pyramid
      attr_reader :org_units, :org_unit_groupsets

      def initialize(org_units:, org_unit_groupsets:)
        @org_units = org_units
        @org_unit_groupsets = org_unit_groupsets
        @org_unit_groupsets_by_id = org_unit_groupsets.index_by(&:ext_id)
        @org_units_by_group_id = org_units.each_with_object({}) do |ou, hash|
          ou.group_ext_ids.each do |group_ext_id|
            hash[group_ext_id] ||= Set.new
            hash[group_ext_id].add(ou)
          end
        end
        @org_units_by_ext_id = org_units.index_by(&:ext_id)
      end

      def org_unit(ext_id)
        org_units_by_ext_id[ext_id]
      end

      def groupset(ext_id)
        raise "No groupset for '#{ext_id}'" unless org_unit_groupsets_by_id[ext_id]
        org_unit_groupsets_by_id[ext_id]
      end

      def orgunits_in_groups(group_ext_ids)
        group_ext_ids.each_with_object(Set.new) do |ext_id, set|
          set.merge(org_units_by_group_id[ext_id])
        end
      end

      private

      attr_reader :org_units_by_group_id, :org_unit_groupsets_by_id, :org_units_by_ext_id
    end
  end
end
