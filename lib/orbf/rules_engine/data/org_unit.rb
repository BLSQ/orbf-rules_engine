# frozen_string_literal: true

module Orbf
  module RulesEngine
    class OrgUnit < Orbf::RulesEngine::ValueObject
      attributes :ext_id, :name, :path, :group_ext_ids

      def to_s
        inspect
      end

      def parent_ext_ids
        path.split('/')[0..-2]
      end

      def group_ext_ids
        @group_ext_ids || []
      end
    end
  end
end
