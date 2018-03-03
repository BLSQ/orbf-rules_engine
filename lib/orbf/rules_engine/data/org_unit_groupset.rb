# frozen_string_literal: true

module Orbf
  module RulesEngine
    class OrgUnitGroupset < Orbf::RulesEngine::ValueObject
      attributes :ext_id, :name, :group_ext_ids
    end
  end
end
