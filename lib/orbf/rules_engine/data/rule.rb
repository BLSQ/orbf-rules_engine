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
        PAYMENT = "payment"
        ENTITIES_AGGREGATION = "entities_aggregation"

        KINDS = [
          ACTIVITY,
          PACKAGE,
          ZONE,
          PAYMENT,
          ENTITIES_AGGREGATION
        ].freeze

        def self.assert_valid(rule_kind)
          return if KINDS.include?(rule_kind)
          raise "Invalid rule kind '#{rule_kind}' only supports #{KINDS}"
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

      def package_kind?
        @kind == Kinds::PACKAGE
      end

      def zone_kind?
        @kind == Kinds::ZONE
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
      end
    end
  end
end
