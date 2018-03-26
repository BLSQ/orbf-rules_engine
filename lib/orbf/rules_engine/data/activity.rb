# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Activity < RulesEngine::ValueObject
      attributes :name, :activity_code, :activity_states

      def states
        activity_states.map(&:state)
      end
    end
  end
end
