# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Tokenizer
      def self.format_keys(expression)
        expression.scan(/%{([\w]+)}/).reject(&:empty?).flatten
      end

      def self.tokenize(expression)
        expression.split(/(,|\/|-|\*|\ |%{|}|\+|\)|\(|\r?\n)/)
      end

      def self.replace_token_from_expression(expression_template, substitutions_template, template_vars)
        tokens = tokenize(expression_template).map do |token|
          substitutions_template[token] ? format(substitutions_template[token], template_vars) : token
        end
        tokens.join("")
      end
    end
  end
end
