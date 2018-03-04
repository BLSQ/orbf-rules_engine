
module Orbf
  module RulesEngine
    def initialize(org_unit, pyramid)
      @org_unit = org_unit
      @pyramid = pyramid
    end

    def to_facts
      parent_ids = org_unit.path.split("/").reject(&:empty?)
      facts = parent_ids.each_with_index
                        .map { |parent_id, index| ["level_#{index + 1}", parent_id] }
                        .to_h
      facts.merge(to_group_set_facts(org_unit))
           .merge("level" => parent_ids.size.to_s)
      end

    private

    attr_reader :org_unit, :pyramid

    def to_group_ids
      org_unit.organisation_unit_groups.map { |n| n["id"] }
    end



    def to_group_set_facts
      group_set_facts = pyramid.org_unit_groups(to_group_ids(org_unit))
                               .each_with_object({}) do |group, facts|
        next unless group
        group.group_set_ids.map do |groupset_id|
          groupset = pyramid.org_unit_group_set(groupset_id)
          facts["groupset_code_#{groupset.code}"] = group.code
        end
      end
    end
  end
end
