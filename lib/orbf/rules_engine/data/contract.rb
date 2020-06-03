module Orbf
  module RulesEngine
    class Contract
      attr_reader :id, :start_period, :end_period, :field_values
      def initialize(field_values, calendar)
        @field_values = field_values
        @id = field_values["id"]
        @org_unit = field_values["org_unit"]
        @start_period = field_values["startcontract"].gsub("-", "").slice(0, 6)
        @end_period = field_values["endcontract"].gsub("-", "").slice(0, 6)
        @calendar = calendar
      end

      def match_period?(period)
        start_month_period = @calendar.periods(period, "monthly")[0]
        (
          start_period <= start_month_period && start_month_period <= end_period
        )
      end

      def org_unit_id
        @org_unit["id"]
      end

      def org_unit_name
        @org_unit["name"]
      end

      def overlaps(contract)
        return false if contract.id == self.id

        (
          contract.start_period < end_period &&
          start_period < contract.end_period
        )
      end

      def to_s
        "Orbf::RulesEngine::Contract##{self.id}(ou=#{org_unit_id},from_to=#{self.start_period}-#{self.end_period},#{org_unit_name},#{field_values}"
      end
    end
  end
end
