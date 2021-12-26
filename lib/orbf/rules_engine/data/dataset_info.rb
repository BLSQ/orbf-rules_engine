
module Orbf
  module RulesEngine
    class DatasetInfo < RulesEngine::ValueObject::Model(:payment_rule_code, :frequency, :data_elements, :orgunits)
    end
  end
end
