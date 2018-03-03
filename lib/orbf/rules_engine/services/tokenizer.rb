# frozen_string_literal: true

module Orbf
  module RulesEngine
    class Tokenizer
      def self.format_keys(expression)
        expression.scan(/%{([\w]+)}/).reject(&:empty?).flatten
      end

      def self.tokenize(expression)
        expression.split(/(,|\/|-|\*|\ |%{|}|\+|\)|\()/)
      end

      def self.replace_token_from_expression(expression_template, substitions_template, template_vars)
        tokenize(expression_template).map do |token|
          substitions_template[token] ? format(substitions_template[token], template_vars) : token
        end.join('')
      end
    end
  end
end
