module Orbf
  module RulesEngine
    class PackageArguments < Orbf::RulesEngine::ValueObject
      attributes :periods, :orgunits, :datasets_ext_ids, :package

      def to_s
        inspect
      end
    end
  end
end
