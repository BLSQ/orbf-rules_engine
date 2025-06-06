require "orbf/rules_engine/version"

require "dentaku"
require "json"
require "dhis2"
require "set"
require "active_support/time"
require "active_support/core_ext/enumerable"

require_relative "./rules_engine/value_object"
require_relative "./rules_engine/assertions.rb"
require_relative "./rules_engine/log"
require_relative "./rules_engine/services/tokenizer"
require_relative "./rules_engine/services/period_converter"
require_relative "./rules_engine/services/period_iterator"
require_relative "./rules_engine/services/ethiopian_period_converter"
require_relative "./rules_engine/services/ethiopian_period_iterator"
require_relative "./rules_engine/services/ethiopian_converter"
require_relative "./rules_engine/services/ethiopian_calendar"
require_relative "./rules_engine/services/ethiopian_v2_calendar"
require_relative "./rules_engine/services/period_facts"
require_relative "./rules_engine/services/solver_error_handler"
require_relative "./rules_engine/services/solver"
require_relative "./rules_engine/services/value_formatter"
require_relative "./rules_engine/services/codifier"
require_relative "./rules_engine/services/gregorian_calendar"
require_relative "./rules_engine/services/contract_service"

require_relative "./rules_engine/data/activity"
require_relative "./rules_engine/data/activity_state"
require_relative "./rules_engine/data/org_unit"
require_relative "./rules_engine/data/org_unit_with_facts"
require_relative "./rules_engine/data/org_unit_group"
require_relative "./rules_engine/data/org_unit_groupset"
require_relative "./rules_engine/data/org_units"
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
require_relative "./rules_engine/data/dataset_info"
require_relative "./rules_engine/data/invoice"
require_relative "./rules_engine/data/contract"

require_relative "./rules_engine/fetch_data/datasets_resolver"
require_relative "./rules_engine/fetch_data/periods_resolver"
require_relative "./rules_engine/fetch_data/group_orgunits_resolver"
require_relative "./rules_engine/fetch_data/contract_orgunits_resolver"
require_relative "./rules_engine/fetch_data/datasets/compute_orgunits"
require_relative "./rules_engine/fetch_data/datasets/compute_data_elements"
require_relative "./rules_engine/fetch_data/datasets/compute_datasets"
require_relative "./rules_engine/fetch_data/resolve_arguments"
require_relative "./rules_engine/fetch_data/fetch_data_value_sets"
require_relative "./rules_engine/fetch_data/fetch_data_analytics"
require_relative "./rules_engine/fetch_data/fetch_data"
require_relative "./rules_engine/fetch_data/orgunit_facts"
require_relative "./rules_engine/fetch_data/pyramid_factory"
require_relative "./rules_engine/fetch_data/create_pyramid"
require_relative "./rules_engine/services/fetch_and_solve"
require_relative "./rules_engine/services/groups_synchro"

require_relative "./rules_engine/builders/sum_if"
require_relative "./rules_engine/builders/dhis2_indexed_values"
require_relative "./rules_engine/builders/alias_post_processor"
require_relative "./rules_engine/builders/solver_factory"
require_relative "./rules_engine/builders/calculator_factory"
require_relative "./rules_engine/builders/variables_builder_support"
require_relative "./rules_engine/builders/contract_variables_builder"
require_relative "./rules_engine/builders/entities_aggregation_formula_variables_builder"
require_relative "./rules_engine/builders/activity_variables_builder"
require_relative "./rules_engine/builders/activity_formula_combo_values_expander"
require_relative "./rules_engine/builders/activity_combo_variables_builder"
require_relative "./rules_engine/builders/indicator_expression_parser"
require_relative "./rules_engine/builders/indicator_evaluator"
require_relative "./rules_engine/builders/activity_formula_values_expander"
require_relative "./rules_engine/builders/activity_formula_combo_variables_builder"
require_relative "./rules_engine/builders/activity_formula_variables_builder"
require_relative "./rules_engine/builders/decision_variables_builder"
require_relative "./rules_engine/builders/package_decision_variables_builder"
require_relative "./rules_engine/builders/activity_constant_variables_builder"
require_relative "./rules_engine/builders/payment_formula_variables_builder"
require_relative "./rules_engine/builders/payment_formula_values_expander"
require_relative "./rules_engine/builders/package_variables_builder"
require_relative "./rules_engine/builders/zone_formula_variables_builder"
require_relative "./rules_engine/builders/zone_activity_formula_variables_builder"
require_relative "./rules_engine/builders/spans/spans"

require_relative "./rules_engine/printers/graphviz_project_printer"
require_relative "./rules_engine/printers/graphviz_variables_printer"
require_relative "./rules_engine/printers/invoice_cli_printer"
require_relative "./rules_engine/printers/invoice_printer"
require_relative "./rules_engine/printers/dhis2_values_printer"

module Orbf
  module RulesEngine
  end
end
