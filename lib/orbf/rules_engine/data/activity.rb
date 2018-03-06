# frozen_string_literal: true

module Orbf
  module RulesEngine
    class ActivityState < Orbf::RulesEngine::ValueObject
      attributes :state, :ext_id, :name, :kind, :formula

      KIND_CONSTANT = "constant"
      KIND_DATA_ELEMENT = "data_element"
      KIND_INDICATOR = "indicator"

      KINDS = [KIND_CONSTANT, KIND_DATA_ELEMENT, KIND_INDICATOR].freeze

      def self.new_constant(state:, name:, formula:)
        with(
          state:   state.to_s,
          name:    name,
          formula: formula,
          kind:    KIND_CONSTANT,
          ext_id:  nil
        )
      end

      def self.new_data_element(state:, name:, ext_id:)
        with(
          state:   state.to_s,
          name:    name,
          ext_id:  ext_id,
          kind:    KIND_DATA_ELEMENT,
          formula: nil
        )
      end

      def self.new_indicator(state:, name:, ext_id:, expression:)
        with(
          state:   state.to_s,
          name:    name,
          ext_id:  ext_id,
          kind:    KIND_INDICATOR,
          formula: expression
        )
      end

      def constant?
        kind == KIND_CONSTANT
      end

      def data_element?
        kind == KIND_DATA_ELEMENT
      end

      def after_init
        raise "Kind #{kind} must be one of #{TYPES}" unless KINDS.include?(kind.to_s)
      end
    end

    class Activity < RulesEngine::ValueObject
      attributes :activity_code, :activity_states

      def states
        activity_states.map(&:state)
      end
    end
  end
end
