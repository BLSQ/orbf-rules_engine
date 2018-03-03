# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Rule
      attr_reader :formulas, :kind
      attr_accessor :package

      KINDS = %w[activity package zone payment].freeze

      def initialize(args)
        @kind = args[:kind].to_s

        @formulas = args[:formulas]
        @formulas.each do |formula|
          formula.rule = self
        end
        validate
      end

      def activity_kind?
        @kind == 'activity'
      end

      def package_kind?
        @kind == 'package'
      end

      def zone_kind?
        @kind == 'zone'
      end

      def payment_kind?
        @kind == 'payment'
      end

      private

      def validate
        raise "Kind #{kind} must be one of #{KINDS}" unless KINDS.include?(kind)
      end
    end
  end
end
