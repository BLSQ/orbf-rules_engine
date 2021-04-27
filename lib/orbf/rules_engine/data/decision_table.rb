# frozen_string_literal: true

require "csv"
module Orbf
  module RulesEngine
    class DecisionTable
      attr_reader :rules, :start_period, :end_period

      HEADER_SEPERATOR = ":"

      def initialize(csv_string, start_period:, end_period:)
        @start_period = start_period
        @end_period = end_period
        csv = CSV.parse(csv_string, headers: true)
        @headers = csv.headers.compact.map(&:freeze)

        @rules = csv.each_with_index.map do |row, index|
          DecisionRule.new(@headers, row, index)
        end
      end

      def match_period?(period)
        return true unless @start_period && @end_period

        start_period <= period && period <= end_period
      end

      def find(raw_hash)
        hash = {}
        raw_hash.map { |k, v| hash[DecisionTable.to_in_header(k)] = v }
        matching_rules = @rules.select { |rule| rule.matches?(hash) }

        if matching_rules.any?
          matching_rules = matching_rules.sort_by(&:specific_score)
          return matching_rules.last.apply
        end

        nil
      end

      def headers(type = nil)
        if type
          @headers.select { |header| header.start_with?(type.to_s) }.map { |h| h.split(HEADER_SEPERATOR)[1] }
        else
          @headers
        end
      end

      def to_s
        @rules.map(&:to_s).join("\n")
      end

      def inspect
        to_s
      end

      @headers ||= {}

      class << self
        def to_in_header(header)
          @headers[header] ||= "in:#{header}"
        end
      end
    end
  end
end
