RSpec.describe "Packages cross referencies" do

  REFERENCED_DATA_ELEMENT_EXT_ID =  "referenced_de_shared_ext_id"

  let(:project) do
    Orbf::RulesEngine::Project.new(
      packages:      [
        referenced_package,
        main_package
      ],
      payment_rules: [
      ],
      dhis2_params:  {
        url:      "http://dhis2.oo",
        user:     "dhis2u",
        password: "dhis2pwd"
      }
    )
  end

  let(:orgunits) do
    [
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "1",
        path:          "country_id/county_id/1",
        name:          "African Foundation Baptist",
        group_ext_ids: ["contracted"]
      )
    ]
  end

  let(:orgunit_groups) do
    [
      Orbf::RulesEngine::OrgUnitGroup.with(
        ext_id: "contracted",
        name:   "C",
        code:   "contracted"
      )
    ]
  end

  let(:pyramid) do
    Orbf::RulesEngine::Pyramid.new(
      org_units:          orgunits,
      org_unit_groups:    orgunit_groups,
      org_unit_groupsets: []
    )
  end

  let(:referenced_activities) do
    [
      Orbf::RulesEngine::Activity.with(
        name:            "referenced_act1",
        activity_code:   "referenced_act1",
        activity_states: [
          Orbf::RulesEngine::ActivityState.new_constant(
            state:   :achieved,
            name:    "referenced_act1_achieved",
            formula: "10"
          )
        ]
      )
    ]
  end

  let(:referenced_package) do
    Orbf::RulesEngine::Package.new(
      code:                   :referenced,
      kind:                   :single,
      frequency:              :quarterly,
      org_unit_group_ext_ids: ["contracted"],
      activities:             referenced_activities,
      rules:                  [
        Orbf::RulesEngine::Rule.new(
          kind:     :activity,
          formulas: [
            Orbf::RulesEngine::Formula.new(
              "amount", "achieved * 100", ""
            )
          ]
        ),
        Orbf::RulesEngine::Rule.new(
          kind:     :package,
          formulas: [
            Orbf::RulesEngine::Formula.new(
              "referenced_amount", "SUM(%{amount_values})", "", single_mapping: REFERENCED_DATA_ELEMENT_EXT_ID
            )
          ]
        )
      ]
    )
  end

  let(:main_activities) do
    [
      Orbf::RulesEngine::Activity.with(
        name:            "m_act1",
        activity_code:   "m_act1",
        activity_states: [
          Orbf::RulesEngine::ActivityState.new_data_element(
            state:  :score,
            ext_id: REFERENCED_DATA_ELEMENT_EXT_ID,
            name:   "referenced_de_shared"
          )
        ]
      )
    ]
  end

  let(:main_package) do
    Orbf::RulesEngine::Package.new(
      code:                   :main,
      kind:                   :single,
      frequency:              :quarterly,
      org_unit_group_ext_ids: ["contracted"],
      activities:             main_activities,
      rules:                  [
        Orbf::RulesEngine::Rule.new(
          kind:     :activity,
          formulas: [
            Orbf::RulesEngine::Formula.new(
              "amount", "score * 2", ""
            )
          ]
        ),
        Orbf::RulesEngine::Rule.new(
          kind:     :package,
          formulas: [
            Orbf::RulesEngine::Formula.new(
              "quantity_amount", "SUM(%{amount_values})", "", single_mapping: "final_score"
            )
          ]
        )
      ]
    )
  end

  let(:expected_dhis2_values) do
    [{ dataElement: REFERENCED_DATA_ELEMENT_EXT_ID,
       orgUnit:     "1",
       period:      "2016Q1",
       value:       1000,
       comment:     "referenced_referenced_amount_for_1_and_2016q1" },
     { dataElement: "final_score",
       orgUnit:     "1",
       period:      "2016Q1",
       value:       2000,
       comment:     "main_quantity_amount_for_1_and_2016q1" }]
  end

  it "should instantiate xxx" do
    fetch_and_solve = Orbf::RulesEngine::FetchAndSolve.new(
      project,
      "1",
      "2016Q1",
      pyramid:     pyramid,
      mock_values: []
    )
    fetch_and_solve.call

    puts JSON.pretty_generate(fetch_and_solve.solver.build_problem)

    expect(fetch_and_solve.exported_values).to eq(expected_dhis2_values)
  end
end
