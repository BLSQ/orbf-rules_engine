# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Codifier
      CACHE = {}
      REGEXP_VALIDATION = /\A[a-z_0-9]+\z/

      def self.codify(string)
        in_cache = CACHE[string]

        return in_cache if in_cache

        if REGEXP_VALIDATION.match(string)
          CACHE[string] = string
          string
        else
          codified = string.parameterize(separator: "_").tr("-", "_").gsub("__", "_")
          CACHE[string] = codified
          codified
        end
      end
    end
  end
end
