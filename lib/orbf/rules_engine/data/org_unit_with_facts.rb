# frozen_string_literal: true

module Orbf
  module RulesEngine
    # behave like OrgUnit but holds extra facts
    class OrgUnitWithFacts < Orbf::RulesEngine::ValueObject
      attributes :orgunit, :facts

      def method_missing(method, *args)
        if orgunit.respond_to?(method)
            orgunit.send(method, *args)
        else
          super
        end
      end
    end
  end
end
