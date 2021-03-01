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
          if package.include_main_orgunit
            orgunits
          else
            orgunits[1..-1] || []
          end
        else
          orgunits
        end
      end

      def ref_orgunit
        orgunits[0]
      end

      def secondary_orgunits
        return orgunits if package.zone? && package.include_main_orgunit

        orgunits[1..-1]
      end

      def empty?
        orgunits.empty?
      end

      private

      attr_reader :orgunits, :package
    end
  end
end
