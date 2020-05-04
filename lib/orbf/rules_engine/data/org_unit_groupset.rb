# frozen_string_literal: true

module Orbf
  module RulesEngine
    class OrgUnitGroupset < Orbf::RulesEngine::ValueObject::Model(:ext_id, :name, :group_ext_ids, :code)
    end
  end
end
