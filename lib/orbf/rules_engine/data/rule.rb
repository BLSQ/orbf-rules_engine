# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Rule
      attr_reader :formulas, :kind, :decision_tables
      attr_accessor :package

      module Kinds
        ACTIVITY = "activity"
        PACKAGE = "package"
        ZONE = "zone"
        ZONE_ACTIVITY = "zone_activity"
        PAYMENT = "payment"
        ENTITIES_AGGREGATION = "entities_aggregation"

        KINDS = [
          ACTIVITY,
          PACKAGE,
          ZONE,
          ZONE_ACTIVITY,
          PAYMENT,
          ENTITIES_AGGREGATION
        ].freeze

        def self.assert_valid(rule_kind)
          return if KINDS.include?(rule_kind)
          raise "Invalid rule kind '#{rule_kind}' only supports #{KINDS}"
        end

        def self.all
          KINDS
        end
      end

      KNOWN_ATTRIBUTES = %i[kind formulas decision_tables].freeze

      def initialize(args)
        Assertions.valid_arg_keys!(args, KNOWN_ATTRIBUTES)
        @kind = args[:kind].to_s
        @formulas = Array(args[:formulas])
        @formulas.each do |formula|
          formula.rule = self
        end
        @decision_tables = Array(args[:decision_tables])
        validate
      end

      def activity_kind?
        @kind == Kinds::ACTIVITY
      end

      def activity_related_kind?
        activity_kind? || zone_activity_kind?
      end

      def package_kind?
        @kind == Kinds::PACKAGE
      end

      def zone_kind?
        @kind == Kinds::ZONE
      end

      def zone_activity_kind?
        @kind == Kinds::ZONE_ACTIVITY
      end

      def zone_related_kind?
        zone_kind? || zone_activity_kind?
      end

      def payment_kind?
        @kind == Kinds::PAYMENT
      end

      def entities_aggregation_kind?
        @kind == Kinds::ENTITIES_AGGREGATION
      end

      private

      def validate
        Kinds.assert_valid(kind)
        validate_formulas_references
      end

      def validate_formulas_references
        exportable_formula_codes = formulas.map(&:exportable_formula_code).compact.reject(&:empty?)
        return if exportable_formula_codes.none?
        known_formula_codes = formulas.map(&:code)
        unknown_exportable_formulas_codes = exportable_formula_codes - known_formula_codes
        raise "Unknown exportable_formula_code : #{unknown_exportable_formulas_codes.join(', ')}. see #{known_formula_codes.join(', ')}" if unknown_exportable_formulas_codes.any?
      end
    end
  end
end
