# frozen_string_literal: true

module Orbf
  module RulesEngine
    class ResolveArguments
      def initialize(project:, pyramid:, orgunit_ext_id:, invoicing_period:, contract_service: nil)
        @project = project
        @pyramid = pyramid
        @orgunit_ext_id = orgunit_ext_id
        @invoicing_period = invoicing_period
        @main_orgunit = pyramid.org_unit(orgunit_ext_id)
        @contract_service = contract_service
        raise "unknown orgunit '#{orgunit_ext_id}'" unless @main_orgunit
      end

      def call
        package_arguments = build_package_arguments
        package_arguments.each do |k, v|
          Orbf::RulesEngine::Log.call " #{k.code} #{k.kind} ---- #{v.orgunits.map(&:ext_id)}, #{v.periods}"
        end
        package_arguments.reject { |_k, v| v.orgunits.empty? }.to_h
      end

      private

      attr_reader :project, :pyramid, :orgunit_ext_id, :invoicing_period, :main_orgunit

      def build_package_arguments
        project.packages.each_with_object({}) do |package, hash|
          raw_orgunits = build_orgunit_resolver(package, pyramid, main_orgunit).call
          next if raw_orgunits.empty?

          orgunits = decorate_with_facts(raw_orgunits)

          hash[package] = PackageArguments.with(
            periods:          PeriodsResolver.new(package, invoicing_period).call,
            orgunits:         OrgUnits.new(
              package:  package,
              orgunits: orgunits
            ),
            datasets_ext_ids: DatasetsResolver.dataset_extids(package),
            package:          package
          )
        end
      end

      def build_orgunit_resolver(package, pyramid, main_orgunit)
        if @contract_service
          ContractOrgunitsResolver.new(package, pyramid, main_orgunit, @contract_service, invoicing_period)
        else
          GroupOrgunitsResolver.new(package, pyramid, main_orgunit)
        end
      end

      def decorate_with_facts(orgunits)
        orgunits.map do |org_unit|
          OrgUnitWithFacts.new(
            orgunit: org_unit,
            facts:   OrgunitFacts.new(org_unit: org_unit, pyramid: pyramid, contract_service: @contract_service, invoicing_period: invoicing_period).to_facts
          )
        end
      end
    end
  end
end
