# frozen_string_literal: true

module Orbf
  module RulesEngine
    module Spans
      def self.matching_span(name, rule_kind)
        RulesEngine::Rule::Kinds.assert_valid(rule_kind)
        SPANS.find do |span|
          span.supports?(rule_kind) && span.frequencies(name).any?
        end
      end

      class Span
        FREQUENCIES = {
          ""           => %w[monthly quarterly yearly],
          "_yearly"    => ["yearly"],
          "_quarterly" => ["quarterly"],
          "_quarterly_nov" => ["quarterly_nov"],
          "_monthly"   => ["monthly"]
        }.freeze

        def prefix(name)
          FREQUENCIES.each_key do |frequency_var|
            suffix_to_check = "#{suffix}#{frequency_var}_values"
            return name[0..-(suffix_to_check.size + 2)] if name.end_with?(suffix_to_check)
          end
          nil
        end

        def frequencies(name, frequencies = FREQUENCIES)
          frequencies.each do |frequency_var, frequencies|
            suffix_to_check = "#{suffix}#{frequency_var}_values"
            return frequencies if name.end_with?(suffix_to_check)
          end
          []
        end

        def supports?(rule_kind)
          rule_kind == "activity"
        end
      end

      class PreviousYear < Span
        def suffix
          "previous_year"
        end

        def periods(invoicing_period, name, calendar)
          target_year = previous_year(invoicing_period)
          frequencies(name).each_with_object([]) do |frequency, arr|
            arr.push(*calendar.periods(target_year, frequency))
          end
        end

        def previous_year(invoicing_period)
          year = Integer(invoicing_period[0..3])
          (year - 1).to_s
        end
      end

      class PreviousYearSameQuarter < PreviousYear
        def suffix
          "previous_year_same_quarter"
        end

        def periods(invoicing_period, name, calendar)
          target_year = previous_year(invoicing_period)
          same_quarter = invoicing_period[-2..-1]
          period = "#{target_year}#{same_quarter}"
          frequencies(name).each_with_object([]) do |frequency, arr|
            arr.push(*calendar.periods(period, frequency))
          end
        end
      end

      class CurrentQuarter < Span
        QUARTER_FREQUENCIES = {
          ""               => %w[monthly],
          "_yearly"        => ["yearly"],
          "_quarterly_nov" => ["quarterly_nov"],
          "_quarterly"     => ["quarterly"],
          "_monthly"       => ["monthly"]
        }.freeze

        def suffix
          "current_quarter"
        end

        def periods(invoicing_period, name, calendar)
          quarter = calendar.periods(invoicing_period, "quarterly").first
          frequencies(name, QUARTER_FREQUENCIES).each_with_object([]) do |frequency, arr|
            arr.push(*calendar.periods(quarter, frequency))
          end
        end

        def supports?(rule_kind)
          rule_kind == "activity"
        end
      end

      class CurrentQuarterNov < Span
        QUARTER_FREQUENCIES = {
          ""               => %w[monthly],
        }.freeze

        def suffix
          "current_quarter_nov"
        end

        def periods(invoicing_period, name, calendar)
          quarter = calendar.periods(invoicing_period, "quarterly_nov").first

          results = frequencies(name, QUARTER_FREQUENCIES).each_with_object([]) do |frequency, arr|
            arr.push(*calendar.periods(quarter, frequency))
          end
          results
        end

        def supports?(rule_kind)
          rule_kind == "activity"
        end
      end


      class PreviousCycle < Span
        def suffix
          "previous"
        end

        def periods(invoicing_period, _name, calendar)
          quarter = calendar.periods(invoicing_period, "quarterly").first
          calendar.periods(quarter, "monthly")
                  .select { |period| period < invoicing_period }
        end

        def supports?(rule_kind)
          rule_kind == "payment"
        end
      end

      class SlidingWindow < Span
        REGEX = /_last_(\d+)_([a-z]+)_?([a-z]+)?_window_values/.freeze
        def suffix
          "window"
        end

        def prefix(name)
          name.gsub(REGEX, "")
        end

        def exclusive_offset_for(modifier, name)
          if modifier == "exclusive"
            1
          elsif modifier.nil?
            0
          else
            raise "Sorry unsupported modifier mode : #{name}"
          end
        end

        def periods(invoicing_period, name, calendar)
          matches = name.match(REGEX)

          offset = matches[1]
          unit = matches[2]
          exclusive_offset = exclusive_offset_for(matches[3], name)

          if unit == "months"
            unit = "monthly"
            offset = (Integer(offset) - 1).months
            offset_end = exclusive_offset.months
          elsif unit == "quarters"
            unit = "quarterly"
            offset = (Integer(offset) - 1).months * 3
            offset_end = exclusive_offset.months * 3
          else
            raise "Sorry '#{unit}' is not supported only months and quarters in #{name}"
          end

          period_start = PeriodConverter.as_date_range(invoicing_period).first
          previous_range = (period_start - offset - offset_end)..(period_start - offset_end)
          result = PeriodIterator.extract_periods(previous_range, unit)
          result
        end

        def frequencies(name, _frequencies = FREQUENCIES)
          if name =~ REGEX
            ["something"]
          else
            []
          end
        end
      end

      SPANS = [PreviousYearSameQuarter.new, PreviousYear.new, PreviousCycle.new, CurrentQuarterNov.new, CurrentQuarter.new,  SlidingWindow.new].freeze
    end
  end
end
