# frozen_string_literal: true

module Orbf
  module RulesEngine
    class ValueFormatter
      def self.format(value)
        val_as_i = value.to_i
        val_as_f = value.to_f
        val_as_i.to_f == val_as_f ? val_as_i : val_as_f
      end
    end
  end
end
