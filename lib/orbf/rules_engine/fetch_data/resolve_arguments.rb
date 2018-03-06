# frozen_string_literal: true

module Orbf
  module RulesEngine
    class ResolveArguments
      def initialize(project:, pyramid:, orgunit_ext_id:, invoicing_period:)
        @project = project
        @pyramid = pyramid
        @orgunit_ext_id = orgunit_ext_id
        @invoicing_period = invoicing_period
        @main_orgunit = pyramid.org_unit(orgunit_ext_id)
      end

      def call
        package_arguments = build_package_arguments
        package_arguments.each do |k, v|
          Orbf::RulesEngine::Log.call " #{k.code} #{k.kind} ---- #{v.orgunits.map(&:ext_id)}"
        end
        package_arguments
      end

      private

      attr_reader :project, :pyramid, :orgunit_ext_id, :invoicing_period, :main_orgunit

      def build_package_arguments
        project.packages.each_with_object({}) do |package, hash|
          next unless match_group?(package)

          hash[package] = PackageArguments.with(
            periods:          PeriodsResolver.new(package, invoicing_period).call,
            orgunits:         decorate_with_facts(OrgunitsResolver.new(package, pyramid, main_orgunit).call),
            datasets_ext_ids: DatasetsResolver.dataset_extids(package),
            package:          package
          )
        end
      end

      def match_group?(package)
        (package.org_unit_group_ext_ids & main_orgunit.group_ext_ids).any?
      end

      def decorate_with_facts(orgunits)
        orgunits.map do |org_unit|
          OrgUnitWithFacts.new(
            orgunit: org_unit,
            facts:   OrgunitFacts.new(org_unit, pyramid).to_facts
          )
        end
      end
    end
  end
end
