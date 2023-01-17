module Orbf
  module RulesEngine
    class PackageArguments < Orbf::RulesEngine::ValueObject
      attributes :periods, :orgunits, :datasets_ext_ids, :package
      attr_reader :periods, :orgunits, :datasets_ext_ids, :package

      def initialize(hash)
        @periods = hash[:periods]
        @orgunits = hash[:orgunits]
        @datasets_ext_ids = hash[:datasets_ext_ids]
        @package = hash[:package]
        freeze
      end
    end
  end
end
