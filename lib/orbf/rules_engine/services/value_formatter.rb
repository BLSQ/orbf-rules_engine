# frozen_string_literal: true

module Orbf
  module RulesEngine
    class ValueFormatter
      def self.format(value)
        return nil unless value
        val_as_i = value.to_i
        val_as_f = value.to_f
        val_as_i.to_f == val_as_f ? val_as_i : val_as_f
      end

      def self.d_to_s(decimal, number_of_decimal = 2)
        return decimal.to_i.to_s if number_of_decimal > 2 && decimal.to_i == decimal.to_f
        return decimal.to_f.to_s if number_of_decimal > 2
        return Kernel.format("%.#{number_of_decimal}f", decimal) if decimal.is_a? Numeric
        decimal
      end
    end
  end
end
