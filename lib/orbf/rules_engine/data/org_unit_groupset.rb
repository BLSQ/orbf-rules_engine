# frozen_string_literal: true

module Orbf
  module RulesEngine
    class OrgUnitGroupset < Orbf::RulesEngine::ValueObject
      attributes :ext_id, :name, :group_ext_ids, :code
      attr_reader :ext_id, :name, :group_ext_ids, :code
      def initialize(ext_id:, name:, group_ext_ids:, code:)
        @ext_id = ext_id
        @name = name
        @group_ext_ids = group_ext_ids
        @code = code
        freeze
      end
    end
  end
end
