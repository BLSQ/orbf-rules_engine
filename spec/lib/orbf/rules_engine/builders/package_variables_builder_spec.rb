
RSpec.describe Orbf::RulesEngine::PackageVariablesBuilder do
  let(:orgunits) do
    [
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "1",
        path:          "country_id/county_id/1",
        name:          "African Foundation Baptist",
        group_ext_ids: []
      )
    ]
  end

  let(:activities) do
    [
      Orbf::RulesEngine::Activity.with(
        name:            "act1",
        activity_code:   "act1",
        activity_states: [
          Orbf::RulesEngine::ActivityState.new_data_element(
            state:  :achieved,
            ext_id: "dhis2_act1_achieved",
            name:   "act1_achieved",
            origin: "dataValueSets"
          ),
          Orbf::RulesEngine::ActivityState.new_data_element(
            state:  :target,
            ext_id: "dhis2_act1_target",
            name:   "act1_target",
            origin: "dataValueSets"
          )
        ]
      ),
      Orbf::RulesEngine::Activity.with(
        name:            "act2",
        activity_code:   "act2",
        activity_states: [
          Orbf::RulesEngine::ActivityState.new_data_element(
            state:  :achieved,
            ext_id: "dhis2_act2_achieved",
            name:   "act2_achieved",
            origin: "dataValueSets"
          )
        ]
      )
    ]
  end

  let(:quantity_package) do
    Orbf::RulesEngine::Package.new(
      code:       :quantity,
      kind:       :single,
      frequency:  :monthly,
      activities: activities,
      rules:      [
        Orbf::RulesEngine::Rule.new(
          kind:     :activity,
          formulas: [
            Orbf::RulesEngine::Formula.new(
              "activity_amount", "42", ""
            )
          ]
        ),
        Orbf::RulesEngine::Rule.new(
          kind:     :package,
          formulas: [
            Orbf::RulesEngine::Formula.new(
              "quantity_amount", "SUM(%{activity_amount_values})", ""
            ),
            Orbf::RulesEngine::Formula.new(
              "quantity_amount_bonus", "0.10 * quantity_amount", ""
            )
          ]
        )
      ]
    )
  end

  let(:expected_results) do
    [
      Orbf::RulesEngine::Variable.with(
        key:            "#{quantity_package.code}_quantity_amount_for_1_and_201601",
        period:         "201601",
        expression:     "SUM(quantity_act1_activity_amount_for_1_and_201601, quantity_act2_activity_amount_for_1_and_201601)",
        type:           "package_rule",
        state:          "quantity_amount",
        activity_code:  nil,
        orgunit_ext_id: "1",
        formula:        quantity_package.rules[1].formulas.first,
        package:        quantity_package,
        payment_rule:   nil
      ),
      Orbf::RulesEngine::Variable.with(
        key:            "#{quantity_package.code}_quantity_amount_bonus_for_1_and_201601",
        period:         "201601",
        expression:     "0.10 * quantity_quantity_amount_for_1_and_201601",
        type:           "package_rule",
        state:          "quantity_amount_bonus",
        activity_code:  nil,
        orgunit_ext_id: "1",
        formula:        quantity_package.rules[1].formulas.last,
        package:        quantity_package,
        payment_rule:   nil
      )

    ]
  end

  it "should instantiate per orgunit and period the activity rules values" do
    results = described_class.new(quantity_package,
                                  Orbf::RulesEngine::OrgUnits.new(orgunits: orgunits, package: quantity_package),
                                  "201601").to_variables

    expect(results).to eq_vars(expected_results)
  end
end
