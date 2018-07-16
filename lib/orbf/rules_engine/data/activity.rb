# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Activity < RulesEngine::ValueObject
      attributes :name, :activity_code, :activity_states

      attr_reader :name, :activity_code, :activity_states

      def states
        @states
      end

      def after_init 
        @states ||=activity_states.map(&:state).freeze
      end
    end
  end
end
