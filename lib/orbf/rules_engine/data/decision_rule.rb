# frozen_string_literal: true

module Orbf
  module RulesEngine
    class DecisionRule
      ANY = "*"

      IN_HEADER_PREFIX = "in:"
      OUT_HEADERS_PREFIX = "out:"

      def initialize(headers, row, index)
        @headers = headers
        @index = index
        @row = headers.each_with_object({}) do |header, hash|
          hash[header] = row[header] ? row[header].strip : nil
        end
        @headers_by_type = {}
      end

      def matches?(hash)
        headers(IN_HEADER_PREFIX).all? { |header| hash[header] == @row[header] || @row[header] == ANY }
      end

      def specific_score
        header_in = headers(IN_HEADER_PREFIX)
        star_count = header_in.select { |header| @row[header] == ANY }.size
        [header_in.size - star_count, -1 * @index]
      end

      def headers(type)
        @headers_by_type[type] ||= @headers.select { |header| header.start_with?(type) }
      end

      def apply(hash = {})
        headers(OUT_HEADERS_PREFIX).each do |header|
          hash[to_out_header(header)] = @row[header]
        end
        hash
      end

      def to_s
        @row
      end

      def inspect
        to_s
      end

      private

      def to_out_header(header)
        header.slice(OUT_HEADERS_PREFIX.length..-1)
      end
    end
  end
end
