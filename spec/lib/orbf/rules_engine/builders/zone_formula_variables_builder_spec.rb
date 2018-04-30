
RSpec.describe Orbf::RulesEngine::ZoneFormulaVariablesBuilder do
  let(:orgunits) do
    [
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "1",
        path:          "country_id/county_id/1",
        name:          "African Foundation Baptist",
        group_ext_ids: []
      ),
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "2",
        path:          "country_id/county_id/2",
        name:          "African Foundation Baptist",
        group_ext_ids: []
      )
    ]
  end

  let(:package) do
    Orbf::RulesEngine::Package.new(
      code:       :facility,
      kind:       :single,
      frequency:  :monthly,
      activities: [],
      rules:      [
        Orbf::RulesEngine::Rule.new(
          kind:     :package,
          formulas: [
            Orbf::RulesEngine::Formula.new(
              "number_of_indicators_reported", "42", ""
            )
          ]
        ),
        Orbf::RulesEngine::Rule.new(
          kind:     :zone,
          formulas: [
            Orbf::RulesEngine::Formula.new(
              "total_weighted_district_reported", "SUM(%{number_of_indicators_reported_values})", ""
            ),
            Orbf::RulesEngine::Formula.new(
              "sample_zone_formula", "14 / total_weighted_district_reported",""
            )
          ]
        )
      ]
    )
  end

  let(:expected_result) do
    [
      Orbf::RulesEngine::Variable.with(
        period:         "2016Q1",
        key:            "total_weighted_district_reported_for_2016q1",
        expression:     "SUM(facility_number_of_indicators_reported_for_1_and_2016q1,facility_number_of_indicators_reported_for_2_and_2016q1)",
        state:          "total_weighted_district_reported",
        type:           "zone_rule",
        activity_code:  nil,
        orgunit_ext_id: nil,
        formula:        package.rules.last.formulas.first,
        package:        package,
        payment_rule:   nil
      ),
      Orbf::RulesEngine::Variable.with(
        period:         "2016Q1",
        key:            "sample_zone_formula_for_2016q1",
        expression:     "14 / total_weighted_district_reported_for_2016q1",
        state:          "sample_zone_formula",
        type:           "zone_rule",
        activity_code:  nil,
        orgunit_ext_id: nil,
        formula:        package.rules.last.formulas.last,
        package:        package,
        payment_rule:   nil
      ),

    ]
  end

  it "gives access to package vars for all org units" do
    result = described_class.new(package, orgunits, "2016Q1").to_variables
    expect(result).to eq_vars(expected_result)
  end
end
