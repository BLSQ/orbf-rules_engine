# frozen_string_literal: true

module Orbf
  module RulesEngine
    class ValueObject
      attr_reader :values

      def ==(other)
        eql?(other)
      end

      def init_with(coder)
        @values = coder.map.transform_keys(&:to_sym)
      end

      def eql?(other)
        self.class == other.class && values == other.values
      end

      delegate :hash, to: :values

      def to_s
        inspect
      end

      def to_h
        values
      end

      def to_json(options = nil)
        to_h.to_json(options)
      end

      def self.Model(*keys)
        klass = Class.new(self)
        klass.set_keys(keys)
        klass
      end

      def self.call(values)
        o = allocate
        o.instance_variable_set(:@values, values)
        o
      end

      def self.set_keys(keys)
        im = instance_methods
        keys.each do |key|
          meth = :"#{key}="
          module_eval("def #{key}; @values[:#{key}] end", __FILE__, __LINE__) unless im.include?(key)
          module_eval("def #{meth}(v); @values[:#{key}] = v end", __FILE__, __LINE__) unless im.include?(meth)
        end
      end

      private

      def after_init
        # override at will
      end

      class << self
        def with(hash)
          i = call(hash)
          i.send(:after_init)
          i
        end
      end
    end
  end
end
