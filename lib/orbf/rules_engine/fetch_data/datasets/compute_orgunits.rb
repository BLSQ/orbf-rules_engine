module Orbf
  module RulesEngine
    module Datasets
      class ComputeOrgunits
        def initialize(project, pyramid, group_ext_id)
          @pyramid = pyramid
          @project = project
          @group_ext_id = group_ext_id
          @registry = Hash.new { |h, k| h[k] = Set.new }
        end

        def call
          fill_registry

          registry
        end

        private

        attr_reader :registry, :group, :project, :pyramid, :group_ext_id

        def fill_registry
          pyramid.orgunits_in_groups([group_ext_id]).each do |orgunit|
            project.packages.each do |package|
              # assume the fuzzy groups synchronisation is enough
              # and so keep the groups to synchronise the datasets
              # and not the contracts
              # see contract_service.synchronise_groups
              resolved_orgunits = GroupOrgunitsResolver.new(
                package: package, pyramid: pyramid, main_orgunit:orgunit
              ).call
              orgunits = resolved_orgunits.out_list
              orgunits.push(resolved_orgunits.ref_orgunit) if package.zone?
              registry[package.code].merge(orgunits)
            end
          end
        end
      end
    end
  end
end
