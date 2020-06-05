require "json"

module Orbf
  module RulesEngine
    class ContractService
      def initialize(program_id:, all_event_sql_view_id:, dhis2_connection:, calendar:)
        @program_id = program_id
        @all_event_sql_view_id = all_event_sql_view_id
        @dhis2_connection = dhis2_connection
        @calendar = calendar
      end

      def program
        @program ||= begin
          dhis2_connection.programs.find(@program_id,
                                         fields:
                                                 "id,name,programStages[programStageDataElements[dataElement[id,name,code,optionSet[id,name,code,options[id,name]]]]",
                                         paging: false)
        end
      end

      def mappings
        @mappings ||= begin
          data_elements = program.program_stages.flat_map do |ps|
            ps["program_stage_data_elements"].map do |psde|
              psde["data_element"]
            end
          end

          data_elements.each_with_object({}) { |de, mappings| mappings[de["id"]] = de }
        end
      end

      def find_all
        @all_contracts ||= begin
          raw_events = dhis2_connection.get(
            "/sqlViews/" +
              @all_event_sql_view_id +
                "/data.json?var=programId:" +
                @program_id +
                "&paging=false"
          )
          events = raw_events["list_grid"]["rows"].map { |e| to_event(e) }
          events.map { |e| to_contract(e) }
        end
      end

      def for(org_unit_id, period)
        select_contracts = find_all.select do |contract|
          contract.org_unit_id == org_unit_id && contract.match_period?(period)
        end
        if select_contracts.size > 1
          raise "Overlapping contracts for #{org_unit_id} and period #{period} : #{select_contracts}"
        end

        select_contracts[0]
      end

      def for_subcontract(main_org_unit_id, period)
        find_all.select do |contract|
          contract.field_values["contract_main_orgunit"] == main_org_unit_id && contract.match_period?(period)
        end
      end

      def for_groups(groups_codes, period)
        find_all.select do |contract|
          (contract.codes & groups_codes) && contract.match_period?(period)
        end
      end

      private

      attr_reader :dhis2_connection

      def to_event(row)
        data_vals = JSON.parse(row[1]["value"])
        data_values = data_vals.keys.map do |k|
          data_vals[k]["dataElement"] = k
          data_vals[k]
        end
        {
          "event"        => row[0],
          "orgUnit"      => row[2],
          "orgUnitName"  => row[3],
          "program"      => row[4],
          "programStage" => row[5],
          "dataValues"   => data_values
        }
      end

      def to_contract(event)
        contract_field_values = {
          "id"       => event["event"],
          "org_unit" => { "id" => event["orgUnit"], "name" => event["orgUnitName"] }
        }
        event["dataValues"].each do |dv|
          de = mappings[dv["dataElement"]]
          contract_field_values[de["code"]] = dv["value"]
        end
        Orbf::RulesEngine::Contract.new(contract_field_values, @calendar)
      end
    end
  end
end
