module Orbf
module RulesEngine
  class InvoicePrinter
    attr_reader :variables, :solution

    def initialize(variables, solution)
      @variables = variables
      @solution = solution
      @variables_by_key = @variables.group_by(&:key)
                                    .each_with_object({}) { |(k, v), hash| hash[k] = v.first }
    end

    def print
      solution_as_string = solution.each_with_object({}) { |(k, v), hash| hash[k] = d_to_s(v, 10) }
      variables.group_by { |v| [v.package, v.orgunit_ext_id] }
               .each do |package_orgunit, vars|
        package, orgunit = package_orgunit
        Orbf::RulesEngine::Log.call "---------- #{package} #{orgunit}"
        package.activities.each_with_index do |activity, index|
          codes = (package.activity_rules.flat_map(&:formulas).map(&:code) + activity.states)
          values = codes.each_with_object({}) do |state, hash|
            vars.select { |v| v.state == state && v.activity_code == activity.activity_code }
                .each do |activity_variable|
              hash[state] = solution[activity_variable.key]
            end
          end
          headers(values) if index.zero?
          Orbf::RulesEngine::Log.call "#{values.values.map { |v| d_to_s(v) }.join("\t")} #{activity.activity_code}"
        end
        vars.select { |var| var.activity_code.nil? }.each do |var|
          explanation_package(var, solution_as_string)
        end
      end
    end

    def headers(values)
      Orbf::RulesEngine::Log.call wrap((values.keys + ["activity_name"]).each_with_index.map { |v, i| "#{v}(#{i})" }.join("\t"), 120, "")
      Orbf::RulesEngine::Log.call (0..values.keys.size).map(&:to_s).join("\t")
    end

    def explanation_package(var, solution_as_string)
      Orbf::RulesEngine::Log.call " ---- " + var.state +
                            "\n\t" + d_to_s(solution[var.key]) +
                            "\n\t" + var.formula.expression +
                            "\n\t" + Tokenizer.replace_token_from_expression(var.expression, solution_as_string, {}) +
                            "\n\t" + wrap(var.expression)
    end

    def wrap(s, width = 120, extra = "\t\t")
      s.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n#{extra}")
    end

    def d_to_s(decimal, number_of_decimal = 2)
      return decimal.to_i.to_s if number_of_decimal > 2 && decimal.to_i == decimal.to_f
      return decimal.to_f.to_s if number_of_decimal > 2
      return format("%.#{number_of_decimal}f", decimal) if decimal.is_a? Numeric
      decimal
    end
  end
end
end