# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Activity < RulesEngine::ValueObject::Model(:name, :activity_code, :activity_states)

      def states
        @states ||= activity_states.map(&:state).freeze
      end
    end
  end
end
