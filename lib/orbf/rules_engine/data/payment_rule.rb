# frozen_string_literal: true

module Orbf
  module RulesEngine
    class PaymentRule
      module Frequencies
        MONTHLY = "monthly"
        QUARTERLY = "quarterly"
        FREQUENCIES = [MONTHLY, QUARTERLY].freeze

        def self.assert_valid(payment_rule_frequency)
          return if FREQUENCIES.include?(payment_rule_frequency)
          raise "Invalid payment rule frequency '#{payment_rule_frequency}' only supports #{FREQUENCIES}"
        end
      end

      KNOWN_ATTRIBUTES = %i[packages rule frequency code].freeze

      attr_reader(*KNOWN_ATTRIBUTES)

      def initialize(args)
        Assertions.valid_arg_keys!(args, KNOWN_ATTRIBUTES)
        @packages = Array(args[:packages])
        @rule = args[:rule]
        @frequency = args[:frequency].to_s
        @code = args[:code].to_s
        validate
      end

      def frequency=(f)
        @frequency = f.to_s
      end

      def monthly?
        frequency == Frequencies::MONTHLY
      end

      def to_json(options = nil)
        to_h.to_json(options)
      end

      def to_h
        {
          code:      @code,
          frequency: @frequency,
          packages:  packages.map(&:to_h),
          rule:      @rule.to_h
        }
      end

      private

      def validate
        raise "rule must be kind '#{Rule::Kinds::PAYMENT}'" unless rule.payment_kind?
        Frequencies.assert_valid(@frequency)
      end
    end
  end
end
