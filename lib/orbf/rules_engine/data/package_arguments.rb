module Orbf
  module RulesEngine
    class PackageArguments < Orbf::RulesEngine::ValueObject
      attributes :periods, :orgunits, :datasets_ext_ids, :package
      attr_reader :periods, :orgunits, :datasets_ext_ids, :package

      def initialize(periods:, orgunits:, datasets_ext_ids:, package:)
        @periods = periods
        @orgunits = orgunits
        @datasets_ext_ids = datasets_ext_ids
        @package = package
        freeze
      end

      def to_json(options = nil)
        to_h.to_json(options)
      end

      def to_h
        {
          periods:          periods,
          orgunits:         orgunits,
          datasets_ext_ids: datasets_ext_ids,
          package_code:     package.code
        }
      end
    end
  end
end
