module Orbf
  module RulesEngine
    module Datasets
      class ComputeDatasets
        def initialize(project:, pyramid:, group_ext_id:)
          @data_elements_per_payment_rule_and_frequency = ComputeDataElements.new(project).call
          @orgunits_per_package = ComputeOrgunits.new(
            project, pyramid, group_ext_id
          ).call
        end

        def call
          datasets = data_elements_per_payment_rule_and_frequency.map do |k, data_elements|
            payment_rule = k[0]
            frequency = k[1]
            build_infos(payment_rule, frequency, data_elements)
          end
          datasets
        end

        private

        attr_reader :data_elements_per_payment_rule_and_frequency, :orgunits_per_package

        def build_infos(payment_rule, frequency, data_elements)
          orgunits = payment_rule.packages.each_with_object(Set.new) do |package, set|
            next unless orgunits_per_package[package.code]
            set.merge(orgunits_per_package[package.code])
          end
          Orbf::RulesEngine::DatasetInfo.new(
            payment_rule_code: payment_rule.code,
            frequency:         frequency,
            data_elements:     data_elements.to_a,
            orgunits:          orgunits.to_a
          )
        end
      end
    end
  end
end
