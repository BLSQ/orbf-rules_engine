# frozen_string_literal: true

module Orbf
  module RulesEngine
    class ValueFormatter
      # When given an integer or a float, special care is taken to
      # format it to the simplest accurate description. E.g.
      #
      #      format("1.0") => 1
      #      format("1.01") => 1.01
      #
      # Nil, booleans and arrays are just returned, not formatted in
      # any way.
      def self.format(value)
        return nil if value.nil?
        return value if boolean?(value)
        return value if array?(value)

        val_as_i = value.to_i
        val_as_f = value.to_f
        val_as_i.to_f == val_as_f ? val_as_i : val_as_f
      end

      def self.d_to_s(decimal, number_of_decimal = 2)
        return decimal.to_s if boolean?(decimal)
        return decimal.to_s if array?(decimal)
        return decimal.to_i.to_s if number_of_decimal > 2 && decimal.to_i == decimal.to_f
        return decimal.to_f.to_s if number_of_decimal > 2
        return Kernel.format("%.#{number_of_decimal}f", decimal) if decimal.is_a? Numeric
        decimal
      end

      def self.boolean?(o)
        o.is_a?(TrueClass) || o.is_a?(FalseClass)
      end

      def self.array?(o)
        o.is_a? Array
      end
    end
  end
end
