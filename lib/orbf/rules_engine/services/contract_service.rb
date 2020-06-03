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
              de = psde["data_element"]
              de["code"] = Codifier.codify(de["code"])
              de
            end
          end

          data_elements.each_with_object({}) { |de, mappings| mappings[de["id"]] = de }
        end
      end

      def find_all
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

      private

      attr_reader :dhis2_connection

      def to_event(row)
        dataVals = JSON.parse(row[1]["value"])
        dataValues = dataVals.keys.map do |k|
          dataVals[k]["dataElement"] = k
          dataVals[k]
        end
        {
          "event"        => row[0],
          "orgUnit"      => row[2],
          "orgUnitName"  => row[3],
          "program"      => row[4],
          "programStage" => row[5],
          "dataValues"   => dataValues
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
