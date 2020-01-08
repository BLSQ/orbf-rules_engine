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

      KNOWN_ATTRIBUTES = %i[packages rule frequency code project].freeze

      attr_reader(*KNOWN_ATTRIBUTES)

      def initialize(args)
        Assertions.valid_arg_keys!(args, KNOWN_ATTRIBUTES)
        @packages = Array(args[:packages])
        @rule = args[:rule]
        @frequency = args[:frequency].to_s
        @code = args[:code].to_s
        @project = args[:project]
        validate
      end

      def project=(proj)
        @project = proj
      end

      def calendar
        @project.calendar
      end

      def frequency=(f)
        @frequency = f.to_s
      end

      def monthly?
        frequency == Frequencies::MONTHLY
      end

      private

      def validate
        raise "rule must be kind '#{Rule::Kinds::PAYMENT}'" unless rule.payment_kind?
        Frequencies.assert_valid(@frequency)
      end
    end
  end
end
