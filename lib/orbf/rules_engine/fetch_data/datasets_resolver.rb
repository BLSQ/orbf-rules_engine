# frozen_string_literal: true

module Orbf
  module RulesEngine
    class DatasetsResolver
      def self.dataset_extids(package)
        package.dataset_ext_ids
      end
    end
  end
end
