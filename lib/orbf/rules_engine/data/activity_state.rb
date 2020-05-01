module Orbf
  module RulesEngine
    class ActivityState < Orbf::RulesEngine::ValueObject::Model(:state, :ext_id, :name, :kind, :formula, :origin, :category_combo_ext_id)

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

        def self.assert_valid_kind(activity_state_kind, instance)
          return if KINDS_SET.include?(activity_state_kind)

          raise "Invalid activity state kind '#{activity_state_kind}' only supports #{KINDS} : #{instance.debug_info}"
        end

        def self.assert_valid_kind_and_formula(kind, formula, instance)
          assert_valid_kind(kind, instance)
          return unless Kinds.formula_required?(kind) && formula.nil?

          raise "formula required for #{kind} : #{instance.debug_info}"
        end
      end

      module Origins
        ORIGIN_DATAVALUESETS = "dataValueSets".freeze
        ORIGIN_ANALYTICS = "analytics".freeze
        ORIGINS = [
          ORIGIN_DATAVALUESETS,
          ORIGIN_ANALYTICS
        ].freeze

        def self.assert_valid_origin(activity_state_origin, instance)
          return if ORIGINS.include?(activity_state_origin)

          raise "Invalid activity state origin '#{activity_state_origin}' only supports #{ORIGINS}: #{instance.debug_info}"
        end
      end

      def self.new_constant(state:, name:, formula:)
        with(
          state:   state,
          name:    name,
          formula: formula,
          kind:    Kinds::KIND_CONSTANT,
          origin:  Origins::ORIGIN_DATAVALUESETS,
          ext_id:  nil
        )
      end

      def self.new_data_element(state:, name:, ext_id:, origin:, category_combo_ext_id: nil)
        with(
          state:          state,
          name:           name,
          ext_id:         ext_id,
          kind:           Kinds::KIND_DATA_ELEMENT,
          origin:         origin,
          formula:        nil,
          category_combo_ext_id: category_combo_ext_id
        )
      end

      def self.new_indicator(state:, name:, ext_id:, expression:, origin:)
        with(
          state:   state,
          name:    name,
          ext_id:  ext_id,
          kind:    Kinds::KIND_INDICATOR,
          origin:  origin,
          formula: expression
        )
      end

      def origin
        @values[:origin] || "dataValueSets"
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

      def origin_analytics?
        origin == Origins::ORIGIN_ANALYTICS
      end

      def origin_data_value_sets?
        origin == Origins::ORIGIN_DATAVALUESETS
      end

      def debug_info
        "state:'#{state}' ext_id:'#{ext_id}' name:'#{name}' kind:'#{kind}' formula:'#{formula}' origin:'#{origin}'"
      end

      def after_init
        raise "State is mandatory #{debug_info}" unless state

        @values[:state] = state.to_s
        Kinds.assert_valid_kind_and_formula(kind, formula,self )
        Origins.assert_valid_origin(origin, self)
      end
    end
  end
end
