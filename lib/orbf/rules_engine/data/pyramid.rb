# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Pyramid
      attr_reader :org_units, :org_unit_groupsets, :org_unit_groups

      def initialize(org_units:, org_unit_groups:, org_unit_groupsets:)
        @org_units = org_units
        @org_unit_groups_by_id = org_unit_groups.index_by(&:ext_id)
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

      def org_units_for(ext_ids)
        Array(ext_ids).each_with_object(Set.new) do |ext_id, set|
          set.merge([org_units_by_ext_id[ext_id]])
        end
      end

      def groupset(ext_id)
        raise "No groupset for '#{ext_id}'" unless org_unit_groupsets_by_id[ext_id]
        org_unit_groupsets_by_id[ext_id]
      end

      def groups(ext_ids)
        org_unit_groups_by_id.fetch_values(*ext_ids)
      end

      def belong_to_group(org_unit, group_id)
        orgunits_in_groups(group_id).include?(org_unit)
      end

      def orgunits_in_groups(group_ext_ids)
        Array(group_ext_ids).each_with_object(Set.new) do |ext_id, set|
          set.merge(org_units_by_group_id[ext_id])
        end
      end

      def groupsets_for_group(group_ext_id)
        org_unit_groupsets.select { |groupset| groupset.group_ext_ids.include?(group_ext_id) }
      end

      private

      attr_reader :org_unit_groups_by_id, :org_units_by_group_id, :org_unit_groupsets_by_id, :org_units_by_ext_id
    end
  end
end
