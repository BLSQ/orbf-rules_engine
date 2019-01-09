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

      def empty?
        orgunits.empty?
      end

      def to_json(options = nil)
        to_h.to_json(options)
      end

      def to_h
        {
          out_list:           out_list.map(&:to_h),
          ref_orgunit:        ref_orgunit.to_h,
          secondary_orgunits: secondary_orgunits.map(&:to_h)
        }
      end

      private

      attr_reader :orgunits, :package
    end
  end
end
