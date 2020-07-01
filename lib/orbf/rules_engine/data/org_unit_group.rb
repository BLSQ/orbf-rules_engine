# frozen_string_literal: true

module Orbf
  module RulesEngine
    class OrgUnitGroup < Orbf::RulesEngine::ValueObject
      attributes :ext_id, :name, :code
      attr_reader :ext_id, :name, :code
      def initialize(ext_id:, name:, code:)
        @ext_id = ext_id
        @name = name
        @code = code
      end

      def code_downcase
        @code.downcase
      end
    end
  end
end
