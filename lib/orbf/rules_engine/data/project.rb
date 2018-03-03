# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Project
      attr_reader :packages, :payment_rules, :dhis2_params

      def initialize(args)
        @packages = args[:packages] || []
        @payment_rules = args[:payment_rules] || []
        @dhis2_params = args[:dhis2_params] || {}
      end
    end
  end
end
