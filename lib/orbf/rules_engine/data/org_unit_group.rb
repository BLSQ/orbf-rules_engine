# frozen_string_literal: true

module Orbf
  module RulesEngine
    class OrgUnitGroup < Orbf::RulesEngine::ValueObject::Model(:ext_id, :name, :code)
      def code_downcase
        code.downcase
      end
    end
  end
end
