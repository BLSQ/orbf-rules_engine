# frozen_string_literal: true

module Orbf
  module RulesEngine
    class OrgUnit < Orbf::RulesEngine::ValueObject
      attributes :ext_id, :name, :path, :group_ext_ids

      attr_reader :ext_id, :name, :path, :group_ext_ids, :parent_ext_ids

      def initialize(hash)
        @ext_id = hash[:ext_id]
        @name = hash[:name]
        @path = hash[:path]
        @group_ext_ids = hash[:group_ext_ids] || []
      end

      def parent_ext_ids
        @parent_ext_ids ||= path.split("/").reject(&:empty?)
      end

      def eql?(other)
        self.class == other.class && ext_id == other.ext_id
      end

      delegate :hash, to: :ext_id
    end
  end
end
