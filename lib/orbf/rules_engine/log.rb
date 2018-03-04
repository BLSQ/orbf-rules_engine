# frozen_string_literal: true

# rubocop:disable Rails/Output
module Orbf
  module RulesEngine
    module Log
      def self.call(string)
        puts string if ENV["LOG_LEVEL"] == "debug"
      end

      def self.error(string)
        puts "ERROR : #{string}"
      end
    end
  end
end
# rubocop:enable Rails/Output
