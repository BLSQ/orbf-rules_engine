

RSpec.describe Orbf::RulesEngine::ContractVariablesBuilder do
  CONTRACT_GROUP_ID = "contract1_group_id".freeze
  PRIMARY_GROUP_ID = "district_group_id".freeze

  let(:district_orgunit1) do
    Orbf::RulesEngine::OrgUnit.with(
      ext_id:        "1",
      path:          "country_id/county_id/1",
      name:          "District 1",
      group_ext_ids: [PRIMARY_GROUP_ID, CONTRACT_GROUP_ID]
    )
  end

  let(:orgunits) do
    [
      district_orgunit1,
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "2",
        path:          "country_id/county_id/2",
        name:          "PMA2",
        group_ext_ids: ["pma", "public", CONTRACT_GROUP_ID]
      ),
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "4",
        path:          "country_id/county_id/4",
        name:          "PMA4",
        group_ext_ids: ["pma", "public", CONTRACT_GROUP_ID]
      )
    ]
  end

  let(:package) do
    Orbf::RulesEngine::Package.new(
      code:            "quality_eval_subcontract",
      kind:            :subcontract,
      group_ext_ids:   [PRIMARY_GROUP_ID],
      groupset_ext_id: "contracts",
      frequency:       "monthly",
      activities:      [
        Orbf::RulesEngine::Activity.with(
          activity_code:   "act1",
          activity_states: [
            Orbf::RulesEngine::ActivityState.with(
              state:   :achieved,
              ext_id:  "dhis2_act1_achieved",
              name:    "act1_achieved",
              kind:    "data_element",
              formula: nil
            ),
            Orbf::RulesEngine::ActivityState.with(
              state:   :target,
              ext_id:  "dhis2_act1_target",
              name:    "act1_target",
              kind:    "data_element",
              formula: nil
            )
          ]
        )
      ],
      rules:           []
    )
  end

  let(:expected_variables) do
    [
      Orbf::RulesEngine::Variable.with(
        period:         "2016",
        key:            "#{package.code}_act1_achieved_for_1_and_2016",
        expression:     "SUM(#{package.code}_act1_achieved_raw_for_1_and_2016, #{package.code}_act1_achieved_raw_for_2_and_2016, #{package.code}_act1_achieved_raw_for_4_and_2016)",
        state:          "achieved",
        activity_code:  "act1",
        type:           "contract",
        orgunit_ext_id: district_orgunit1.ext_id,
        formula:        nil,
        package:        package
      ),
      Orbf::RulesEngine::Variable.with(
        period:         "2016",
        key:            "#{package.code}_act1_target_for_1_and_2016",
        expression:     "SUM(#{package.code}_act1_target_raw_for_1_and_2016, #{package.code}_act1_target_raw_for_2_and_2016, #{package.code}_act1_target_raw_for_4_and_2016)",
        state:          "target",
        activity_code:  "act1",
        type:           "contract",
        orgunit_ext_id: district_orgunit1.ext_id,
        formula:        nil,
        package:        package
      )
    ]
  end

  it "creates proper variables" do
    variables = described_class.new(package, orgunits, "2016").to_variables
    expect(variables).to eq_vars expected_variables
  end
end
