# frozen_string_literal: true

module Orbf
  module RulesEngine
    class DecisionRule
      ANY = "*"

      IN_HEADERS = "in:"
      OUT_HEADERS = "out:"

      def initialize(headers, row, index)
        @headers = headers
        @index = index
        @row = headers.map do |header|
          [header, row[header] ? row[header].strip : nil]
        end.to_h
        @headers_by_type = {}
      end

      def matches?(hash)
        headers(IN_HEADERS).all? { |header| hash[header] == @row[header] || @row[header] == ANY }
      end

      def specific_score
        header_in = headers(IN_HEADERS)
        star_count = header_in.select { |header| @row[header] == ANY }.size
        [header_in.size - star_count, -1 * @index]
      end

      def headers(type)
        @headers_by_type[type] ||= @headers.select { |header| header.start_with?(type) }
      end

      def apply(hash = {})
        headers(OUT_HEADERS).each do |header|
          hash[header.slice(4..-1)] = @row[header]
        end
        hash
      end

      def [](key)
        @row[key]
      end

      def to_s
        @row
      end

      def inspect
        to_s
      end
    end
  end
end
