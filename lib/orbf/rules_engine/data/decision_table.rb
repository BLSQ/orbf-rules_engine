# frozen_string_literal: true

require "csv"
module Orbf
  module RulesEngine
    class DecisionTable
      attr_reader :rules

      def initialize(csv_string)
        csv = CSV.parse(csv_string, headers: true)
        @headers = csv.headers.compact.map(&:freeze)

        @rules = csv.each_with_index.map do |row, index|
          DecisionRule.new(@headers, row, index)
        end
      end

      def find!(raw_hash)
        values = find(raw_hash)
        raise "no extra facts for #{raw_hash} in #{@headers}" unless values
        values
      end

      def find(raw_hash)
        hash = {}
        raw_hash.map { |k, v| hash[to_in_header(k)] = v }
        matching_rules = @rules.select { |rule| rule.matches?(hash) }

        if matching_rules.any?
          matching_rules = matching_rules.sort_by(&:specific_score) if matching_rules.size > 1
          return matching_rules.last.apply
        end

        nil
      end

      def headers(type = nil)
        if type
          @headers.select { |header| header.start_with?(type.to_s) }.map { |h| h.split(":")[1] }
        else
          @headers
        end
      end

      def to_s
        @rules.to_s
      end

      def inspect
        to_s
      end

      private

      def to_in_header(header)
        @@headers ||= {}
        @@headers[header] ||= "in:#{header}"
      end
    end
  end
end
