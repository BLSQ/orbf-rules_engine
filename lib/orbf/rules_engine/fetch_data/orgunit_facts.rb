module Orbf
  module RulesEngine
    class OrgunitFacts
      def initialize(org_unit:, pyramid:, contract_service:, invoicing_period:)
        @org_unit = org_unit
        @pyramid = pyramid
        @contract_service = contract_service
        @invoicing_period = invoicing_period
      end

      def to_facts
        level_facts.merge(@contract_service ? to_contract_facts : to_group_set_facts)
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
          facts["groupset_origin"] = "groups"
        end
      end

      def to_contract_facts
        contract = @contract_service.for(org_unit.ext_id, @invoicing_period)
        contract_facts = {}

        if contract
          @contract_service.group_based_data_elements.each do |data_element|
            if contract.field_values[data_element["code"]]
              value_code = Codifier.codify(contract.field_values[data_element["code"]])
              contract_facts["groupset_code_#{data_element['code']}"] = value_code
            end
          end
          contract_facts["groupset_origin"] = "contracts"
        end
        contract_facts
      end
    end
  end
end
