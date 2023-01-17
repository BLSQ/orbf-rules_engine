# frozen_string_literal: true

module Orbf
  module RulesEngine
    class OrgUnitGroup < Orbf::RulesEngine::ValueObject
      attributes :ext_id, :name, :code
      attr_reader :ext_id, :name, :code

      def initialize(hash)
        @ext_id = hash[:ext_id]
        @name = hash[:name]
        @code = hash[:code]
      end

      def code_downcase
        @code.downcase
      end
    end
  end
end
