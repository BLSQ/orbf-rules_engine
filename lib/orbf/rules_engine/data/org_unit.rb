# frozen_string_literal: true

module Orbf
  module RulesEngine
    class OrgUnit < Orbf::RulesEngine::ValueObject
      attributes :ext_id, :name, :path, :group_ext_ids

      def parent_ext_ids
        path.split("/")[0..-2]
      end

      def eql?(other)
        self.class == other.class && ext_id == other.ext_id
      end

      delegate :hash, to: :ext_id

      def group_ext_ids
        @group_ext_ids || []
      end
    end
  end
end
