# frozen_string_literal: true

module Orbf
  module RulesEngine
    class PaymentRule
      attr_reader :packages, :frequency, :rule, :code

      def initialize(args)
        @packages = args[:packages]
        @rule = args[:rule]
        @frequency = args[:frequency].to_s
        @code = args[:code].to_s
        raise 'rule must be kind payment' unless rule.kind == 'payment'
        raise 'no frequency' unless Package::FREQUENCIES.include?(@frequency)
      end

      def frequency=(f)
        @frequency = f.to_s
      end

      def monthly?
        frequency == 'monthly'
      end
    end
  end
end
