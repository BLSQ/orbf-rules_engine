# frozen_string_literal: true

module Orbf
  module RulesEngine
    class OrgUnitGroup < Orbf::RulesEngine::ValueObject
      attributes :ext_id, :name, :code
    end
  end
end
