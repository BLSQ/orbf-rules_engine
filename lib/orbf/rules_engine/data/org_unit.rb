# frozen_string_literal: true

module Orbf
  module RulesEngine
    class OrgUnit < Orbf::RulesEngine::ValueObject::Model(:ext_id, :name, :path, :group_ext_ids)
      def group_ext_ids
        @values.fetch(:group_ext_ids, [])
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
