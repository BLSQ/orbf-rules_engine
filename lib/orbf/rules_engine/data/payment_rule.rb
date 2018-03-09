# frozen_string_literal: true

module Orbf
  module RulesEngine
    class PaymentRule
      KNOWN_ATTRIBUTES = %i[packages rule frequency code].freeze

      attr_reader(*KNOWN_ATTRIBUTES)

      def initialize(args)
        Assertions.valid_arg_keys!(args, KNOWN_ATTRIBUTES)
        @packages = args[:packages]
        @rule = args[:rule]
        @frequency = args[:frequency].to_s
        @code = args[:code].to_s
        raise "rule must be kind payment" unless rule.kind == "payment"
        raise "no frequency" unless Package::FREQUENCIES.include?(@frequency)
      end

      def frequency=(f)
        @frequency = f.to_s
      end

      def monthly?
        frequency == "monthly"
      end
    end
  end
end
