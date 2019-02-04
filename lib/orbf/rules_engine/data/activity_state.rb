module Orbf
  module RulesEngine
    class ActivityState < Orbf::RulesEngine::ValueObject
      attributes :state, :ext_id, :name, :kind, :formula

      module Kinds
        KIND_CONSTANT = "constant".freeze
        KIND_DATA_ELEMENT = "data_element".freeze
        KIND_INDICATOR = "indicator".freeze

        KINDS = [KIND_CONSTANT, KIND_DATA_ELEMENT, KIND_INDICATOR].freeze
        KINDS_SET = KINDS.to_set.freeze
        KINDS_WITH_FORMULA = [KIND_CONSTANT, KIND_INDICATOR].freeze
        KINDS_WITH_FORMULA_SET = KINDS_WITH_FORMULA.to_set.freeze

        def self.formula_required?(kind)
          KINDS_WITH_FORMULA_SET.include?(kind)
        end

        def self.assert_valid_kind(activity_state_kind)
          return if KINDS_SET.include?(activity_state_kind)
          raise "Invalid activity state kind '#{activity_state_kind}' only supports #{KINDS}"
        end

        def self.assert_valid_kind_and_formula(kind, formula)
          assert_valid_kind(kind)
          return unless Kinds.formula_required?(kind) && formula.nil?
          raise "formula required for #{kind}"
        end
      end

      def self.new_constant(state:, name:, formula:)
        with(
          state:   state,
          name:    name,
          formula: formula,
          kind:    Kinds::KIND_CONSTANT,
          ext_id:  nil
        )
      end

      def self.new_data_element(state:, name:, ext_id:)
        with(
          state:   state,
          name:    name,
          ext_id:  ext_id,
          kind:    Kinds::KIND_DATA_ELEMENT,
          formula: nil
        )
      end

      def self.new_indicator(state:, name:, ext_id:, expression:)
        with(
          state:   state,
          name:    name,
          ext_id:  ext_id,
          kind:    Kinds::KIND_INDICATOR,
          formula: expression
        )
      end

      def initialize(state: nil, ext_id: nil, name: nil, kind: nil, formula: nil)
        @state = state
        @ext_id = ext_id
        @name = name
        @kind = kind
        @formula = formula
        after_init
      end

      attr_reader :state, :ext_id, :name, :kind, :formula

      attr_reader :state

      def cache_key
        if constant?
          name
        else
          ext_id
        end
      end

      def constant?
        kind == Kinds::KIND_CONSTANT
      end

      def data_element?
        kind == Kinds::KIND_DATA_ELEMENT
      end

      def indicator?
        kind == Kinds::KIND_INDICATOR
      end

      def after_init
        raise "State is mandatory" unless @state
        @state = state.to_s
        Kinds.assert_valid_kind_and_formula(kind, formula)
      end
    end
  end
end
