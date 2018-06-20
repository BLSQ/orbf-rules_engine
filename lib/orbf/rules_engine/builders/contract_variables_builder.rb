# frozen_string_literal: true

module Orbf
  module RulesEngine
    class ContractVariablesBuilder
      include VariablesBuilderSupport

      ORG_UNITS_COUNT = "org_units_count"

      ORG_UNITS_SUM_IF_COUNT = "org_units_sum_if_count"

      COUNTS = [
        ORG_UNITS_COUNT,
        ORG_UNITS_SUM_IF_COUNT
      ].freeze

      def initialize(package, orgunits, period)
        @package = package
        @ref_orgunit = orgunits.ref_orgunit
        @orgunits = orgunits.to_a
        @period = period
      end

      def to_variables
        return [] unless package.subcontract?

        var_for_invoice_periods + vars_for_spans
      end

      private

      attr_reader :package, :orgunits, :ref_orgunit, :period

      def var_for_invoice_periods
        package.activities.each_with_object([]) do |activity, array|
          filtered_orgunits = SumIf.org_units(orgunits, package, activity)
          package.harmonized_activity_states(activity).each do |activity_state|
            array.push(build_variable(filtered_orgunits, activity, activity_state, period))
          end
          array.push(build_count(ORG_UNITS_COUNT, orgunits.size, activity))
          array.push(build_count(ORG_UNITS_SUM_IF_COUNT, filtered_orgunits.size, activity))
        end
      end

      def vars_for_spans
        periods_from_values_span.each_with_object([]) do |missing_period, vars|
          package.activities.each do |activity|
            filtered_orgunits = SumIf.org_units(orgunits, package, activity)
            package.harmonized_activity_states(activity).each do |activity_state|
              unless activity_state.constant?
                vars.push(build_variable(filtered_orgunits, activity, activity_state, missing_period))
              end
            end
          end
        end
      end

      def periods_from_values_span
        package.activity_rules.flat_map(&:formulas).each_with_object(Set.new) do |formula, set|
          formula.values_dependencies.each do |dependency|
            span = Orbf::RulesEngine::Spans.matching_span(dependency, formula.rule.kind)
            next unless span
            set.merge(span.periods(period, dependency))
          end
        end
      end

      def build_variable(filtered_orgunits, activity, activity_state, period)
        expressions = org_units_expression(filtered_orgunits, activity, activity_state, period)
        expression = activity_state.constant? ? expressions.first : "SUM(#{expressions.join(', ')})"
        key = build_key(package, activity, activity_state, period)

        Orbf::RulesEngine::Variable.new_contract(
          period:         period,
          key:            key,
          expression:     expression,
          state:          activity_state.state.to_s,
          activity_code:  activity.activity_code,
          orgunit_ext_id: ref_orgunit.ext_id,
          package:        package
        )
      end

      # achieved_for_2_and_2016, achieved_for_4_and_2016
      def org_units_expression(filtered_orgunits, activity, activity_state, period)
        filtered_orgunits.map do |orgunit|
          if activity_state.constant?
            name_constant(activity.activity_code, activity_state.state, period)
          else
            suffix_for_activity(
              package.code,
              activity.activity_code,
              suffix_raw(activity_state.state),
              orgunit,
              period
            )
          end
        end
      end

      def build_count(count_code, count, activity)
        Orbf::RulesEngine::Variable.new_contract(
          period:         period,
          key:            suffix_for_id(
            [package.code, activity.activity_code, count_code].join("_"),
            ref_orgunit.ext_id,
            period
          ),
          expression:     count.to_s,
          state:          count_code.to_s,
          activity_code:  activity.activity_code,
          orgunit_ext_id: ref_orgunit.ext_id,
          package:        package
        )
      end

      def build_key(package, activity, activity_state, period)
        suffix_for_id(
          [package.code, activity.activity_code, activity_state.state].join("_"),
          ref_orgunit.ext_id,
          period
        )
      end
    end
  end
end
