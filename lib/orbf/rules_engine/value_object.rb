# frozen_string_literal: true
module Orbf
  module Plugins
    module AfterInitialize
      module ClassMethods
        def call(_)
          v = super
          v.after_init
          v
        end
      end

      module InstanceMethods
        # An empty after_initialize hook, so that plugins that use this
        # can always call super to get the default behavior.
        def after_init
        end
      end
    end
  end
end

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
        def plugin(a_module)
          extend(a_module::ClassMethods)
          include(a_module::InstanceMethods)
        end

        def with(hash)
          i = call(hash)
          i
        end
      end
    end
  end
end
