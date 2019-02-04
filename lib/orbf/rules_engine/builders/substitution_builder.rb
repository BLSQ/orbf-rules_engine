module Orbf
  module RulesEngine
    class SubstitutionBuilder
      class Cache
        def initialize(period)
          @period = period
          @data = {}
        end

        def fetch(cache_key, key, &block)
          @data[:cache_key] ||= {}

          if (value = @data[:cache_key][key])
            value
          else
            @data[:cache_key][key] = block.call
          end
        end

        def period_facts
          return @data[:period_facts] if @data[:period_facts]

          @data[:period_facts] = Orbf::RulesEngine::PeriodFacts.for(@period)
          @data[:period_facts]
        end
      end

      # This will build up a hash with all substitutions and their
      # corresponding values It does this by keeping an internal hash
      # `@result` which gets modified by each method in the `call`
      # method.
      #
      # Calling `call` twice should not make any difference, the
      # result will be the same but it will have to do the
      # computations twice
      #
      # SubstitutionBuilder.new(package: package,
      #                         expression: formula.expression,
      #                         activity_code: activity_code,
      #                         period: period).call
      #
      include VariablesBuilderSupport
      EMPTY_SUBSTITUTIONS = {}.freeze
      LEVELS_RANGES = (1..5).freeze
      attr_accessor :package, :expression, :activity_code, :period
      attr_accessor :result, :cache

      def initialize(package:, expression:, activity_code:, period:, cache: Cache.new)
        @package = package
        @expression = expression
        @activity_code = activity_code
        @period = period
        @result = {}
        @cache = cache
      end

      def self.setup_cache(period)
        Cache.new(period)
      end

      def call
        states_substitutions
        null_substitutions
        level_substitutions
        package_substitutions
        formulas_substitutions
        zone_main_orgunit_substitutions
        decision_table_substitutions
        orgunit_counts_substitutions
        dates_substitutions

        result
      end

      def states_substitutions
        package.activities.each do |activity|
          next if activity_code != activity.activity_code

          package.harmonized_activity_states(activity).each do |activity_state|
            next unless used_in_expression?(activity_state.state)
            result[activity_state.state] = activity_state_substitution(package.code, activity, activity_state)
          end
        end
      end

      def null_substitutions
        activity = package.activities.detect { |candidate| candidate.activity_code == activity_code }
        package.harmonized_activity_states(activity).each do |activity_state|
          next unless used_in_expression?(activity_state.state)
          suffixed_state = suffix_is_null(activity_state.state)

          result[suffixed_state] = suffix_activity_pattern(package.code, activity_code, suffixed_state)
        end
      end

      def level_substitutions
        return EMPTY_SUBSTITUTIONS unless expression.include?("_level_")

        package.states.each do |state|
          LEVELS_RANGES.each do |level_index|
            state_level = state + "_level_#{level_index}"
            next unless used_in_expression?(state_level)

            result[state_level] = suffix_activity_pattern(
              package.code, activity_code, state_level,
              "orgunit_parent_level#{level_index}_id".to_sym
            )
          end
        end
      end

      def package_substitutions
        package.package_rules.flat_map(&:formulas).each do |formula|
          next unless used_in_expression?(formula.code)

          result[formula.code] = suffix_package_pattern(package.code, formula.code)
        end
      end

      def formulas_substitutions
        package.activity_rules.flat_map(&:formulas).each do |formula|
          next unless used_in_expression?(formula.code)

          result[formula.code] = suffix_activity_pattern(package.code, activity_code, formula.code)
        end
      end

      def zone_main_orgunit_substitutions
        return EMPTY_SUBSTITUTIONS unless used_in_expression?("_zone_main_orgunit")

        activity = package.activities.detect { |candidate| candidate.activity_code == activity_code }
        package.harmonized_activity_states(activity).each do |activity_state|
          state_level = activity_state.state + "_zone_main_orgunit"
          next unless used_in_expression?(state_level)

          result[state_level] = suffix_activity_pattern(
            package.code, activity_code, state_level,
            "zone_main_orgunit_id".to_sym
          )
        end
      end

      def decision_table_substitutions
        package.activity_rules
               .flat_map(&:decision_tables)
               .each do |decision_table|
          decision_table.headers(:out).each do |header_out|
            next unless used_in_expression?(header_out)
            result[header_out] = suffix_activity_pattern(package.code, activity_code, header_out)
          end
        end
      end

      def orgunit_counts_substitutions
        return EMPTY_SUBSTITUTIONS unless package.subcontract?

        counts = Orbf::RulesEngine::ContractVariablesBuilder::COUNTS
        counts.each do |count|
          next unless used_in_expression?(count)

          result[count] = suffix_activity_pattern(package.code, activity_code, count)
        end
      end

      def dates_substitutions
        result.merge! cache.period_facts
      end

      private

      def used_in_expression?(code)
        !!expression[code]
      end

      def activity_state_substitution(package_code, activity, activity_state)
        if activity_state.data_element?
          suffix_activity_pattern(package_code, activity.activity_code, activity_state.state)
        elsif activity_state.constant?
          name_constant(activity.activity_code, activity_state.state, period)
        elsif activity_state.indicator?
          suffix_activity_pattern(package_code, activity.activity_code, activity_state.state)
        else
          raise "Unsupported activity state"
        end
      end
    end
  end
end
