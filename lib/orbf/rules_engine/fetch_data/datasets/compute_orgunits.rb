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
              resolved_orgunits = OrgunitsResolver.new(package, pyramid, orgunit).call
              orgunits = resolved_orgunits.out_list
              if package.zone?
                orgunits.push(resolved_orgunits.ref_orgunit)
              end
              registry[package.code].merge(orgunits)
            end
          end
        end
      end
    end
  end
end
