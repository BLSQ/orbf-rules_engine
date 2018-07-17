# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Activity < RulesEngine::ValueObject
      attributes :name, :activity_code, :activity_states

      attr_reader :name, :activity_code, :activity_states

      def initialize(name:, activity_code:, activity_states:)
        @name = name
        @activity_code = activity_code
        @activity_states = activity_states
      end

      def states 
        @states ||= activity_states.map(&:state).freeze
      end
    end
  end
end
