require_relative "../lib/orbf/rules_engine"
require "byebug"

if ENV["DHIS2_PASSWORD"]
  dhis2_params = {
    url:      "https://sandbox.bluesquare.org",
    user:     "admin",
    password: ENV["DHIS2_PASSWORD"]
  }

  dhis2_connection = Dhis2::Client.new(dhis2_params)
  calendar ||= ::Orbf::RulesEngine::GregorianCalendar.new
  program_id = "TwcqxaLn11C"
  all_event_sql_view_id = "QNKOsX4EGEk"

  contract_service = Orbf::RulesEngine::ContractService.new(
    program_id:            program_id,
    all_event_sql_view_id: all_event_sql_view_id,
    dhis2_connection:      dhis2_connection,
    calendar:              calendar
  )

  contracts = contract_service.find_all

  def overlapping_contracts(contracts)
    overlappings = []
    contracts.each do |c1|
      contracts.each do |c2|
        overlappings.push([c1, c2]) if c1.overlaps(c2)
      end
    end
    overlappings
  end

  puts contracts.select { |c| c.match_period?("202212") }.size
  puts contracts.select { |c| c.match_period?("2020Q1") }.size
  puts contracts.select { |c| c.match_period?("2023Q1") }.size
  puts contracts.size
  contracts.group_by(&:org_unit_id).each do |_org_unit_id, ou_contracts|
    overlappings = overlapping_contracts(ou_contracts)
    next if overlappings.empty?

    overlappings.each do |overlaps|
      overlaps.each do |c|
        print(c)
      end
    end
  end
end
