

RSpec.describe Orbf::RulesEngine::ContractVariablesBuilder do
  CONTRACT_GROUP_ID = "contract1_group_id".freeze
  PRIMARY_GROUP_ID = "district_group_id".freeze

  let(:activity) do
    Orbf::RulesEngine::Activity.with(
      name:            "act1",
      activity_code:   "act1",
      activity_states: [
        Orbf::RulesEngine::ActivityState.new_data_element(
          state:  :achieved,
          ext_id: "dhis2_act1_achieved",
          name:   "act1_achieved"
        ),
        Orbf::RulesEngine::ActivityState.new_data_element(
          state:  :target,
          ext_id: "dhis2_act1_target",
          name:   "act1_target"
        )
      ]
    )
  end

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
      Orbf::RulesEngine::OrgUnitWithFacts.new(
        orgunit: district_orgunit1,
        facts:   { "level" => "2" }
      ),
      Orbf::RulesEngine::OrgUnitWithFacts.new(
        orgunit: Orbf::RulesEngine::OrgUnit.with(
          ext_id:        "2",
          path:          "country_id/county_id/2",
          name:          "PMA2",
          group_ext_ids: ["pma", "public", CONTRACT_GROUP_ID]
        ),
        facts:   { "level" => "3" }
      ),
      Orbf::RulesEngine::OrgUnitWithFacts.new(
        orgunit: Orbf::RulesEngine::OrgUnit.with(
          ext_id:        "4",
          path:          "country_id/county_id/4",
          name:          "PMA4",
          group_ext_ids: ["pma", "private", CONTRACT_GROUP_ID]
        ),
        facts:   { "level" => "3" }
      )
    ]
  end

  context "no decision table" do
    let(:package) do
      Orbf::RulesEngine::Package.new(
        code:                   "quality_eval_subcontract",
        kind:                   :subcontract,
        org_unit_group_ext_ids: [PRIMARY_GROUP_ID],
        groupset_ext_id:        "contracts",
        frequency:              "monthly",
        activities:             [activity],
        rules:                  []
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
          package:        package,
          payment_rule:   nil
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
          package:        package,
          payment_rule:   nil
        ),
        Orbf::RulesEngine::Variable.with(
          period:         "2016",
          key:            "quality_eval_subcontract_act1_org_units_count_for_1_and_2016",
          expression:     "3",
          state:          "org_units_count",
          activity_code:  "act1",
          type:           "contract",
          orgunit_ext_id: district_orgunit1.ext_id,
          formula:        nil,
          package:        package,
          payment_rule:   nil
        ),
        Orbf::RulesEngine::Variable.with(
          period:         "2016",
          key:            "quality_eval_subcontract_act1_org_units_sum_if_count_for_1_and_2016",
          expression:     "3",
          state:          "org_units_sum_if_count",
          activity_code:  "act1",
          type:           "contract",
          orgunit_ext_id: district_orgunit1.ext_id,
          formula:        nil,
          package:        package,
          payment_rule:   nil
        )
      ]
    end

    it "creates proper variables" do
      variables = described_class.new(package, orgunits, "2016").to_variables
      expect(variables).to eq_vars expected_variables
    end
  end

  context "with decision table" do
    let(:package) do
      Orbf::RulesEngine::Package.new(
        code:                   "quality_eval_subcontract",
        kind:                   :subcontract,
        org_unit_group_ext_ids: [PRIMARY_GROUP_ID],
        groupset_ext_id:        "contracts",
        frequency:              "monthly",
        activities:             [activity],
        rules:                  [
          Orbf::RulesEngine::Rule.new(
            kind:            :entities_aggregation,
            decision_tables: [
              Orbf::RulesEngine::DecisionTable.new(%(in:level,out:sum_if
                1,false
                2,false
                *,true
              ))
            ]
          )
        ]
      )
    end

    let(:expected_variables) do
      [
        Orbf::RulesEngine::Variable.with(
          period:         "2016",
          key:            "#{package.code}_act1_achieved_for_1_and_2016",
          expression:     "SUM(#{package.code}_act1_achieved_raw_for_2_and_2016, #{package.code}_act1_achieved_raw_for_4_and_2016)",
          state:          "achieved",
          activity_code:  "act1",
          type:           "contract",
          orgunit_ext_id: district_orgunit1.ext_id,
          formula:        nil,
          package:        package,
          payment_rule:   nil
        ),
        Orbf::RulesEngine::Variable.with(
          period:         "2016",
          key:            "#{package.code}_act1_target_for_1_and_2016",
          expression:     "SUM(#{package.code}_act1_target_raw_for_2_and_2016, #{package.code}_act1_target_raw_for_4_and_2016)",
          state:          "target",
          activity_code:  "act1",
          type:           "contract",
          orgunit_ext_id: district_orgunit1.ext_id,
          formula:        nil,
          package:        package,
          payment_rule:   nil
        ),
        Orbf::RulesEngine::Variable.with(
          period:         "2016",
          key:            "quality_eval_subcontract_act1_org_units_count_for_1_and_2016",
          expression:     "3",
          state:          "org_units_count",
          activity_code:  "act1",
          type:           "contract",
          orgunit_ext_id: district_orgunit1.ext_id,
          formula:        nil,
          package:        package,
          payment_rule:   nil
        ),
        Orbf::RulesEngine::Variable.with(
          period:         "2016",
          key:            "quality_eval_subcontract_act1_org_units_sum_if_count_for_1_and_2016",
          expression:     "2",
          state:          "org_units_sum_if_count",
          activity_code:  "act1",
          type:           "contract",
          orgunit_ext_id: district_orgunit1.ext_id,
          formula:        nil,
          package:        package,
          payment_rule:   nil
        )
      ]
    end

    it "creates proper variables without level2 mention" do
      variables = described_class.new(package, orgunits, "2016").to_variables
      expect(variables).to eq_vars expected_variables
    end
  end
end
