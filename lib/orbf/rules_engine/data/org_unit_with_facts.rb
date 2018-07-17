# frozen_string_literal: true

module Orbf
  module RulesEngine
    # behave like OrgUnit but holds extra facts
    class OrgUnitWithFacts < Orbf::RulesEngine::ValueObject
      attributes :orgunit, :facts

      attr_reader :orgunit, :facts

      def initialize(orgunit:, facts:)
        @orgunit = orgunit
        @facts = facts
        freeze
      end

      def eql?(other)
        self.class == other.class && ext_id == other.ext_id
      end

      def ext_id
        @orgunit.ext_id
      end

      def parent_ext_ids
        @orgunit.parent_ext_ids
      end

      delegate :hash, to: :ext_id

      def method_missing(method, *args)
        if orgunit.respond_to?(method)
          orgunit.send(method, *args)
        else
          super
        end
      end
    end
  end
end
