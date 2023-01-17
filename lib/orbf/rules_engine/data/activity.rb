# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Activity < RulesEngine::ValueObject
      attributes :name, :activity_code, :activity_states

      attr_reader :name, :activity_code, :activity_states

      def initialize(hash)
        @name = hash[:name]
        @activity_code = hash[:activity_code]
        @activity_states = hash[:activity_states]
      end

      def states
        @states ||= activity_states.map(&:state).freeze
      end
    end
  end
end
