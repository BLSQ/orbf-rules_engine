# frozen_string_literal: true

module Orbf
  module RulesEngine
    module VariablesBuilderSupport
      def name_constant(activity_code, state, period)
        "#{activity_code}_#{state}_for_#{period.downcase}"
      end

      def suffix_for(package_code, activity_code, orgunit, period)
        suffix_for_id("#{package_code}_#{activity_code}", orgunit.ext_id, period)
      end

      def suffix_for_activity(package_code, activity_code, state, orgunit, period)
        suffix_for_id("#{package_code}_#{activity_code}_#{state}", orgunit.ext_id, period)
      end

      def suffix_for_id_activity(package_code, activity_code, state, orgunit_ext_id, period)
        suffix_for_id("#{package_code}_#{activity_code}_#{state}", orgunit_ext_id, period)
      end

      def suffix_for_values(package_code, activity_code, orgunit, period)
        suffix_for_id("#{package_code}_#{activity_code}_values", orgunit.ext_id, period)
      end

      def suffix_for_package(package_code, formula_code, orgunit, period)
        suffix_for_id("#{package_code}_#{formula_code}", orgunit.ext_id, period)
      end

      def suffix_for_id(code, orgunit_id, period)
        "#{code}_for_#{orgunit_id}_and_#{period.downcase}"
      end

      def suffix_activity_pattern(package_code, activity_code, name, orgunit_pattern = :orgunit_id)
        "#{package_code}_#{activity_code}_#{name}_for_%{#{orgunit_pattern}}_and_%{period}"
      end

      def suffix_package_pattern(package_code, name)
        "#{package_code}_#{name}_for_%{orgunit_id}_and_%{period}"
      end

      def suffix_raw(code)
        "#{code}_raw"
      end
    end
  end
end
