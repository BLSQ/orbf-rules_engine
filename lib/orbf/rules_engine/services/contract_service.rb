require "json"

module Orbf
  module RulesEngine
    class ContractService
      PROGRAM_FIELDS = "id,name,programStages[programStageDataElements[dataElement[id,name,code,optionSet[id,name,code,options[id,code,name]]]]".freeze
      attr_reader :dhis2_connection

      def initialize(program_id:, all_event_sql_view_id:, dhis2_connection:, calendar:)
        @program_id = program_id
        @all_event_sql_view_id = all_event_sql_view_id
        @dhis2_connection = dhis2_connection
        @calendar = calendar
      end

      def program
        @program ||= begin
          dhis2_connection.programs.find(@program_id, fields: PROGRAM_FIELDS, paging: false)
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
          indexes = {}
          raw_events["list_grid"]["headers"].each_with_index do |header, index|
            indexes[header["column"]] = index
          end
          events = raw_events["list_grid"]["rows"].map { |e| to_event(e, indexes) }
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
          (contract.codes & groups_codes).present? && contract.match_period?(period)
        end
      end

      def synchronise_groups(period)
        GroupsSynchro.new(self).synchronise(period)
      end

      def group_based_data_elements
        program.program_stages.flat_map do |ps|
          ps["program_stage_data_elements"].map do |psde|
            psde["data_element"]
          end
        end.select { |de| de["option_set"] }
      end

      private

      def to_event(row, indexes)

        raw_data_values = row[indexes.fetch("data_values")]
        data_vals = raw_data_values.is_a?(String) ? JSON.parse(raw_data_values) : JSON.parse(raw_data_values["value"])
        data_values = data_vals.keys.map do |k|
          data_vals[k]["dataElement"] = k
          data_vals[k]
        end
        {
          "event"        => row[indexes.fetch("event_id")],
          "date"         => row[indexes.fetch("event_date")],
          "orgUnit"      => row[indexes.fetch("org_unit_id")],
          "orgUnitName"  => row[indexes.fetch("org_unit_name")],
          "orgUnitPath"  => row[indexes.fetch("org_unit_path")],
          "program"      => row[indexes.fetch("program_id")],
          "programStage" => row[indexes.fetch("program_stage_id")],
          "dataValues"   => data_values
        }
      end

      def to_contract(event)
        contract_field_values = {
          "id"       => event.fetch("event"),
          "org_unit" => {
            "id"   => event.fetch("orgUnit"),
            "name" => event.fetch("orgUnitName"),
            "path" => event.fetch("orgUnitPath")
          },
          "date"     => event.fetch("date")
        }
        event.fetch("dataValues").each do |dv|
          de = mappings[dv.fetch("dataElement")]
          contract_field_values[de["code"]] = dv["value"]
        end
        Orbf::RulesEngine::Contract.new(contract_field_values, @calendar)
      end
    end
  end
end
