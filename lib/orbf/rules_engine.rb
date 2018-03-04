require "orbf/rules_engine/version"

require "dentaku"
require "json"
require "dhis2"
require "set"
require "active_support/time"
require "active_support/core_ext/enumerable"

require_relative "./rules_engine/value_object"
require_relative "./rules_engine/log"
require_relative "./rules_engine/services/tokenizer"
require_relative "./rules_engine/services/period_converter"
require_relative "./rules_engine/services/period_iterator"
require_relative "./rules_engine/services/solver"
require_relative "./rules_engine/services/value_formatter"
require_relative "./rules_engine/services/codifier"

require_relative "./rules_engine/data/activity"
require_relative "./rules_engine/data/org_unit"
require_relative "./rules_engine/data/org_unit_group"
require_relative "./rules_engine/data/org_unit_groupset"
require_relative "./rules_engine/data/variable"
require_relative "./rules_engine/data/payment_rule"
require_relative "./rules_engine/data/rule"
require_relative "./rules_engine/data/package"
require_relative "./rules_engine/data/project"
require_relative "./rules_engine/data/pyramid"
require_relative "./rules_engine/data/formula"
require_relative "./rules_engine/data/package_arguments"
require_relative "./rules_engine/data/decision_table"
require_relative "./rules_engine/data/decision_rule"

require_relative "./rules_engine/fetch_data/datasets_resolver"
require_relative "./rules_engine/fetch_data/periods_resolver"
require_relative "./rules_engine/fetch_data/orgunits_resolver"
require_relative "./rules_engine/fetch_data/resolve_arguments"
require_relative "./rules_engine/fetch_data/fetch_data"
require_relative "./rules_engine/fetch_data/create_pyramid"
require_relative "./rules_engine/services/fetch_and_solve"

require_relative "./rules_engine/builders/dhis2_indexed_values"
require_relative "./rules_engine/builders/solver_factory"
require_relative "./rules_engine/builders/calculator_factory"
require_relative "./rules_engine/builders/variables_builder_support"
require_relative "./rules_engine/builders/contract_variables_builder"
require_relative "./rules_engine/builders/activity_variables_builder"
require_relative "./rules_engine/builders/indicator_expression_parser"
require_relative "./rules_engine/builders/indicator_evaluator"
require_relative "./rules_engine/builders/activity_formula_values_expander"
require_relative "./rules_engine/builders/activity_formula_variables_builder"
require_relative "./rules_engine/builders/activity_constant_variables_builder"
require_relative "./rules_engine/builders/payment_formula_variables_builder"
require_relative "./rules_engine/builders/payment_formula_values_expander"
require_relative "./rules_engine/builders/package_variables_builder"
require_relative "./rules_engine/builders/zone_formula_variables_builder"
require_relative "./rules_engine/builders/spans/spans"

require_relative "./rules_engine/printers/graphviz_project_printer"
require_relative "./rules_engine/printers/graphviz_variables_printer"
require_relative "./rules_engine/printers/invoice_printer"
require_relative "./rules_engine/printers/dhis2_values_printer"



module Orbf
  module RulesEngine

  end
end
