# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Codifier
      def self.codify(string)
        string.parameterize(separator: "_").tr("-", "_").gsub("__", "_")
      end
    end
  end
end
