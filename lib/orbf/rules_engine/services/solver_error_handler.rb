module Orbf
  module RulesEngine
    class SolverErrorHandler
      class << self
        def on_error(error, problem, variables)
          log_lines(
            ColorizedString["----------- ERROR !!!"].colorize(:red),
            field_message("  Message            : ", error.message),
            field_message("  Problem            : ", JSON.generate(problem)),
            ColorizedString["--------------------"].colorize(:red)
          )
        end

        def on_unbound_variable_error(missing_var_error, problem, variables)
          missing_var = variables.index_by(&:key)[missing_var_error.recipient_variable]
          highlighted_equation = highlight(problem[missing_var_error.recipient_variable], missing_var_error.unbound_variables)
          log_lines(
            ColorizedString["----------- ERROR !!!"].colorize(:red),
            field_message("  Message            : ", missing_var_error.message),
            field_message("  Recipient_variable : ", missing_var_error.recipient_variable.to_s),
            field_message("  Unbound_variables  : ", missing_var_error.unbound_variables.to_s),
            field_message("  Variables          : ", "\n" + missing_var.to_s),
            field_message("  Equation           : ", "\n#{highlighted_equation}"),
            field_message("  Formula expression : ", "\n" + missing_var&.formula&.expression.to_s),
            ColorizedString["--------------------"].colorize(:red)
          )
        end

        private

        def log_lines(*lines)
          puts lines.join("\n")
        end

        def field_message(field_name, message)
          [
            ColorizedString[field_name].colorize(:light_blue),
            message
          ].join(" ")
        end

        def highlight(equation, unbound_variables)
          tokens = Tokenizer.tokenize(equation).map do |token|
            unbound_variables.include?(token) ? ColorizedString[token].colorize(:yellow) : token
          end
          tokens.join("")
        end
      end
    end
  end
end
