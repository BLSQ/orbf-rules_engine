# frozen_string_literal: true

module Orbf
  module RulesEngine
    module Spans
      def self.matching_span(name, rule_kind)
        RulesEngine::Rule::Kinds::assert_valid(rule_kind)
        SPANS.find do |span|
          span.supports?(rule_kind) && span.frequencies(name).any?
        end
      end

      class Span
        FREQUENCIES = {
          ''           => %w[monthly quarterly yearly],
          '_yearly'    => ['yearly'],
          '_quarterly' => ['quarterly'],
          '_monthly'   => ['monthly']
        }.freeze

        def prefix(name)
          FREQUENCIES.each_key do |frequency_var|
            suffix_to_check = "#{suffix}#{frequency_var}_values"
            return name[0..-(suffix_to_check.size + 2)] if name.end_with?(suffix_to_check)
          end
          nil
        end

        def frequencies(name)
          FREQUENCIES.each do |frequency_var, frequencies|
            suffix_to_check = "#{suffix}#{frequency_var}_values"
            return frequencies if name.end_with?(suffix_to_check)
          end
          []
        end

        def supports?(rule_kind)
          rule_kind == 'activity'
        end
      end

      class PreviousYear < Span
        def suffix
          'previous_year'
        end

        def periods(invoicing_period, name)
          target_year = previous_year(invoicing_period)
          frequencies(name).each_with_object([]) do |frequency, arr|
            arr.push(*PeriodIterator.periods(target_year, frequency))
          end
        end

        def previous_year(invoicing_period)
          year = Integer(invoicing_period[0..3])
          (year - 1).to_s
        end
      end

      class PreviousYearSameQuarter < PreviousYear
        def suffix
          'previous_year_same_quarter'
        end

        def periods(invoicing_period, name)
          target_year = previous_year(invoicing_period)
          same_quarter = invoicing_period[-2..-1]
          period = "#{target_year}#{same_quarter}"
          frequencies(name).each_with_object([]) do |frequency, arr|
            arr.push(*PeriodIterator.periods(period, frequency))
          end
        end
      end

      class PreviousCycle < Span
        def suffix
          'previous'
        end

        def periods(invoicing_period, _name)
          quarter = PeriodIterator.periods(invoicing_period, 'quarterly').first
          PeriodIterator.periods(quarter, 'monthly')
                        .select { |period| period < invoicing_period }
        end

        def supports?(rule_kind)
          rule_kind == 'payment'
        end
      end

      SPANS = [PreviousYearSameQuarter.new, PreviousYear.new, PreviousCycle.new].freeze
    end
  end
end
