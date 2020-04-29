# frozen_string_literal: true

module Orbf
  module RulesEngine
    class AliasPostProcessor
      def initialize(variables, default_category_option_combo_ext_id)
        @variables = variables
        @default_category_option_combo_ext_id = default_category_option_combo_ext_id
      end

      def call
        hash_in = index_variables(:dhis2_in_data_element)
        hash_out = index_variables(:dhis2_data_element, :dhis2_coc)
        aliases = []
        hash_in.each do |key, in_vals|
          out_vals = hash_out[key]

          next unless out_vals
          in_vals.each do |in_val|
            out_vals.each do |out_val|
              aliases.push(Variable.new_alias(
                             key:            in_val.key,
                             expression:     out_val.key,
                             period:         in_val.period,
                             state:          nil,
                             activity_code:  in_val.activity_code,
                             orgunit_ext_id: in_val.orgunit_ext_id,
                             formula:        nil,
                             package:        nil,
                             payment_rule:   nil
              ))
            end
          end
        end
        aliases
      end

      private

      attr_reader :variables

      def index_variables(dhis2_element_meth, coc_meth = nil)
        variables.each_with_object({}) do |variable, hash|
          data_element = variable.public_send(dhis2_element_meth)
          coc = coc_meth ? variable.public_send(coc_meth) : nil
          next unless data_element
          components = data_element.split('.')
          key = { period:       variable.dhis2_period,
                  orgunit:      variable.orgunit_ext_id,
                  data_element: components[0],
                  coc: components[1] || coc || @default_category_option_combo_ext_id
              }
          hash[key] ||= []
          hash[key].push variable
        end
      end
    end
  end
end
