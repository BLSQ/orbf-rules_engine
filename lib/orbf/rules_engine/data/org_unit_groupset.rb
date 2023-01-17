# frozen_string_literal: true

module Orbf
  module RulesEngine
    class OrgUnitGroupset < Orbf::RulesEngine::ValueObject
      attributes :ext_id, :name, :group_ext_ids, :code
      attr_reader :ext_id, :name, :group_ext_ids, :code

      def initialize(hash)
        @ext_id = hash[:ext_id]
        @name = hash[:name]
        @group_ext_ids = hash[:group_ext_ids]
        @code = hash[:code]
        freeze
      end
    end
  end
end
