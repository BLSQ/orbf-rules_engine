module Orbf
  module RulesEngine
    class OrgUnits
      include Enumerable

      def initialize(orgunits:, package:)
        @orgunits = orgunits
        @package = package
      end

      def each
        @orgunits.each do |member|
          yield(member)
        end
      end

      def out_list
        if package.subcontract?
          orgunits[0..0]
        elsif package.zone?
          orgunits[1..-1] || []
        else
          orgunits
        end
      end

      def ref_orgunit
        orgunits[0]
      end

      def secondary_orgunits
        orgunits[1..-1]
      end

      private

      attr_reader :orgunits, :package
    end
  end
end
