module Orbf
  module RulesEngine
    class Contract
      KNOWN_FIELDS = %w[contract_start_date contract_end_date id org_unit date].freeze

      attr_reader :id, :start_period, :end_period, :field_values

      def initialize(field_values, calendar)
        @field_values = field_values
        @id = field_values.fetch("id")
        @org_unit = field_values.fetch("org_unit")
        @start_period = field_values.fetch("contract_start_date").gsub("-", "").slice(0, 6)
        @end_period = field_values.fetch("contract_end_date").gsub("-", "").slice(0, 6)
        @calendar = calendar
      end

      def match_period?(period)
        @calendar.periods(period, "monthly").any? do |start_month_period|
          (
            start_period <= start_month_period && start_month_period <= end_period
          )
        end
      end

      def distance(period)
        period_start_month = @calendar.periods(period, "monthly")[0]
        [start_period.to_i - period_start_month.to_i, end_period.to_i - period_start_month.to_i].min
      end

      def org_unit_id
        @org_unit["id"]
      end

      def org_unit_name
        @org_unit["name"]
      end

      def codes
        @codes ||= begin
            other_data_element_values = field_values.entries.select do |(k, v)|
              !KNOWN_FIELDS.include?(k) && v.is_a?(String)
            end
            other_data_element_values.map { |_k, v| v.downcase }
          end
      end

      def overlaps?(contract)
        return false if contract.id == id

        (
          contract.start_period <= end_period &&
          start_period <= contract.end_period
        )
      end

      def to_h
        {
          id:            id,
          org_unit_id:   org_unit_id,
          from_period:   start_period,
          end_period:    end_period,
          org_unit_name: org_unit_name,
          field_values:  field_values
        }
      end

      def inspect
        "#<#{self.class}:0x#{object_id.to_s(16)}(ou=#{org_unit_id},from_to=#{start_period}-#{end_period},#{org_unit_name},#{field_values}"
      end

      def to_s
        JSON.pretty_generate(to_h)
      end

      def self.overlappings(contracts)
        results = []
        contracts.group_by(&:org_unit_id).each do |_org_unit_id, ou_contracts|
          overlappings = overlapping_contracts(ou_contracts)
          results.push(overlappings) if overlappings.present?
        end
        results
      end

      def self.overlapping_contracts(contracts)
        overlappings = []
        contracts.each do |c1|
          contracts.each do |c2|
            overlappings.push([c1, c2]) if c1.overlaps?(c2)
          end
        end
        overlappings
      end
    end
  end
end
