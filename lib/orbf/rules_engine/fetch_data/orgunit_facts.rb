
module Orbf
  module RulesEngine
    class OrgunitFacts
      def initialize(org_unit, pyramid)
        @org_unit = org_unit
        @pyramid = pyramid
      end

      def to_facts
        level_facts.merge(to_group_set_facts)
      end

      private

      attr_reader :org_unit, :pyramid

      def level_facts
        parent_ids = org_unit.path.split("/").reject(&:empty?)
        level_facts = parent_ids.each_with_index
                                .map { |parent_id, index| ["level_#{index + 1}", parent_id] }
                                .to_h
        level_facts.merge("level" => parent_ids.size.to_s)
      end

      def to_group_set_facts
        pyramid.groups(org_unit.group_ext_ids)
               .each_with_object({}) do |group, facts|
          next unless group
          pyramid.groupsets_for_group(group.ext_id).each do |groupset|
            facts["groupset_code_#{groupset.code}"] = group.code
          end
        end
      end
    end
  end
end
