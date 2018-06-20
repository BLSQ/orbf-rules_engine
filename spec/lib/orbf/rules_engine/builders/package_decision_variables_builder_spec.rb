RSpec.describe Orbf::RulesEngine::PackageDecisionVariablesBuilder do
  let(:orgunits) do
    [
      Orbf::RulesEngine::OrgUnitWithFacts.with(
        orgunit: Orbf::RulesEngine::OrgUnit.with(
          ext_id:        "1",
          path:          "country_id/county_id/1",
          name:          "African Foundation Baptist",
          group_ext_ids: []
        ),
        facts:   { "groupset_ppa" => "worldbank", "groupset_type" => "hospital" }
      )
    ]
  end

  let(:package) do
    Orbf::RulesEngine::Package.new(
      code:       :facility,
      kind:       :single,
      frequency:  :quarterly,
      activities: nil,
      rules:      [
        Orbf::RulesEngine::Rule.new(
          kind:            :package,
          formulas:        [],
          decision_tables: [
            Orbf::RulesEngine::DecisionTable.new(%(in:groupset_ppa,in:groupset_type,out:budget_range_1,out:budget_range_2
                  worldbank,fosa,1000,2000
                  worldbank,hospital,3000,4000
                  usaid,hospital,3000,4000
                ))
          ]
        )
      ]
    )
  end

  let(:expected_variables) do
    [
      Orbf::RulesEngine::Variable.with(
        period:         "2016Q1",
        key:            "facility_budget_range_1_for_1_and_2016q1",
        expression:     "3000",
        state:          "budget_range_1",
        activity_code:  nil,
        type:           "package_rule_decision",
        orgunit_ext_id: "1",
        formula:        nil,
        package:        package,
        payment_rule:   nil
      ),

      Orbf::RulesEngine::Variable.with(
        period:         "2016Q1",
        key:            "facility_budget_range_2_for_1_and_2016q1",
        expression:     "4000",
        state:          "budget_range_2",
        activity_code:  nil,
        type:           "package_rule_decision",
        orgunit_ext_id: "1",
        formula:        nil,
        package:        package,
        payment_rule:   nil
      )
    ]
  end

  let(:builder) { Orbf::RulesEngine::PackageDecisionVariablesBuilder.new(package, Orbf::RulesEngine::OrgUnits.new(orgunits: orgunits, package: package), "2016Q1") }

  it "should be able to use the package decision table" do
    expect(builder.to_variables).to eq_vars expected_variables
  end
end
