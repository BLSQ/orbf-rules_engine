class Dhis2ValuesHelper
    def self.ensure_valid(raw_dhis2_values)

        # make sure they are strings and not symbols
        dhis2_values = JSON.parse(JSON.generate(raw_dhis2_values))

        grouped_values = dhis2_values.group_by {|v| [v["dataElement"], v["orgUnit"], v["period"],v["categoryOptionCombo"]]}

        grouped_values.each do |key, values|
            raise "non unique values for #{key} : #{values}" if values.size > 1
        end

        dhis2_values
    end

    def self.uniq(raw_dhis2_values)

        # make sure they are strings and not symbols
        dhis2_values = JSON.parse(JSON.generate(raw_dhis2_values))

        grouped_values = dhis2_values.group_by {|v| [v["dataElement"], v["orgUnit"], v["period"],v["categoryOptionCombo"]]}

        dhis2_values = grouped_values.map do |key, values|
            raise "multiple values for #{key} #{values}" if values.map {|v| v["value"]}.uniq.size > 1
            values.first
        end

        dhis2_values
    end
end