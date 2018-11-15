
RSpec.describe Orbf::RulesEngine::ActivityFormulaVariablesBuilder do
  def action
    described_class.new(
      package,
      Orbf::RulesEngine::OrgUnits.new(orgunits: orgunits, package: package),
      "2016Q1"
    ).to_variables
  end

  let(:activities) do
    [
      Orbf::RulesEngine::Activity.with(
        name:            "act1",
        activity_code:   "act1",
        activity_states: [
          Orbf::RulesEngine::ActivityState.new_data_element(
            state:  :active,
            ext_id: "dhis2_act1_active",
            name:   "act1_active"
          ),
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
    ]
  end

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

  let(:package) do
    Orbf::RulesEngine::Package.new(
      code:       :facility,
      kind:       :single,
      frequency:  :quarterly,
      activities: activities,
      rules:      [
        Orbf::RulesEngine::Rule.new(
          kind:     :activity,
          formulas: [
            Orbf::RulesEngine::Formula.new(
              "percent_achieved",
              "active * safe_div(achieved,sum(%{achieved_previous_year_same_quarter_monthly_values})"
            ),
            Orbf::RulesEngine::Formula.new(
              "allowed",
              "if (percent_achieved < 0.75, 0, percent_achieved)"
            )
          ]
        )
      ]
    )
  end

  let(:basic_formula) { package.activity_rules.first.formulas.last }

  let(:formula_with_span) { package.activity_rules.first.formulas.first }

  let(:expected_results) do
    [
      Orbf::RulesEngine::Variable.with(
        key:            "#{package.code}_act1_percent_achieved_for_1_and_2016q1",
        period:         "2016Q1",
        expression:     "#{package.code}_act1_active_for_1_and_2016q1 * safe_div(#{package.code}_act1_achieved_for_1_and_2016q1,sum(#{package.code}_act1_achieved_for_1_and_201501,#{package.code}_act1_achieved_for_1_and_201502,#{package.code}_act1_achieved_for_1_and_201503)",
        type:           "activity_rule",
        state:          "percent_achieved",
        activity_code:  "act1",
        orgunit_ext_id: "1",
        formula:        formula_with_span,
        package:        package,
        payment_rule:   nil
      ),

      Orbf::RulesEngine::Variable.with(
        key:            "#{package.code}_act1_allowed_for_1_and_2016q1",
        period:         "2016Q1",
        expression:     "if (#{package.code}_act1_percent_achieved_for_1_and_2016q1 < 0.75, 0, #{package.code}_act1_percent_achieved_for_1_and_2016q1)",
        type:           "activity_rule",
        state:          "allowed",
        activity_code:  "act1",
        orgunit_ext_id: "1",
        formula:        basic_formula,
        package:        package,
        payment_rule:   nil
      )
    ]
  end

  it "does the susbstitions of spans and instantiate other states for activity variable" do
    expect(action).to eq_vars(expected_results)
  end

  describe "Spans substitutions" do
    let(:activities) do
      [
        Orbf::RulesEngine::Activity.with(
          name:            "act1",
          activity_code:   "act1",
          activity_states: [
            Orbf::RulesEngine::ActivityState.new_data_element(
              state:  :achieved,
              ext_id: "dhis2_act1_achieved",
              name:   "act1_achieved"
            ),
            Orbf::RulesEngine::ActivityState.new_constant(
              state:   :price,
              name:    "act1_price",
              formula: "100"
            )
          ]
        )
      ]
    end

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

    let(:package) do
      Orbf::RulesEngine::Package.new(
        code:       :facility,
        kind:       :single,
        activities: activities,
        frequency:  :quarterly,
        rules:      [
          Orbf::RulesEngine::Rule.new(
            kind:     :activity,
            formulas: [
              Orbf::RulesEngine::Formula.new(
                "half_price", "price/2"
              )
            ]
          )
        ]
      )
    end

    let(:project) do
      Orbf::RulesEngine::Project.new(
        packages: [package]
      )
    end

    let(:expected_results) do
      [
        Orbf::RulesEngine::Variable.with(
          key:            "#{package.code}_act1_half_price_for_1_and_2016q1",
          period:         "2016Q1",
          expression:     "const_act1_price_for_2016q1/2",
          type:           "activity_rule",
          state:          "half_price",
          activity_code:  "act1",
          orgunit_ext_id: "1",
          formula:        package.rules.first.formulas.first,
          package:        package,
          payment_rule:   nil
        )
      ]
    end

    it "does the susbstitions of spans and instantiate other states for activity variable" do
      expect(action).to eq_vars(expected_results)
    end
  end

  describe "decision_table substitutions" do
    let(:activities) do
      [
        Orbf::RulesEngine::Activity.with(
          name:            "act1",
          activity_code:   "act1",
          activity_states: [
            Orbf::RulesEngine::ActivityState.new_data_element(
              state:  :achieved,
              ext_id: "dhis2_act1_achieved",
              name:   "act1_achieved"
            ),
            Orbf::RulesEngine::ActivityState.new_constant(
              state:   :price,
              name:    "act1_price",
              formula: "100"
            )
          ]
        )
      ]
    end

    let(:package) do
      Orbf::RulesEngine::Package.new(
        code:       :facility,
        kind:       :single,
        activities: activities,
        frequency:  :quarterly,
        rules:      [
          Orbf::RulesEngine::Rule.new(
            kind:            :activity,
            formulas:        [
              Orbf::RulesEngine::Formula.new(
                "equity_price", "price * equity_bonus"
              )
            ],
            decision_tables: [
              Orbf::RulesEngine::DecisionTable.new(%(in:activity_code,in:level_2,out:equity_bonus
                act1,county_id,1
                act2,county_id,2
              ))
            ]
          )
        ]
      )
    end

    let(:expected_results) do
      [
        Orbf::RulesEngine::Variable.with(
          key:            "facility_act1_equity_price_for_1_and_2016q1",
          period:         "2016Q1",
          expression:     "const_act1_price_for_2016q1 * facility_act1_equity_bonus_for_1_and_2016q1",
          type:           "activity_rule",
          state:          "equity_price",
          activity_code:  "act1",
          orgunit_ext_id: "1",
          formula:        package.rules.first.formulas.first,
          package:        package,
          payment_rule:   nil
        )
      ]
    end

    it "substitute decision tables variables" do
      expect(action).to eq_vars(expected_results)
    end
  end

  describe "with main orgunit reference" do
    let(:orgunits) do
      [
        Orbf::RulesEngine::OrgUnit.with(
          ext_id:        "1",
          path:          "country_id/county_id/zonemain",
          name:          "zonemain",
          group_ext_ids: []
        ),
        Orbf::RulesEngine::OrgUnit.with(
          ext_id:        "1",
          path:          "country_id/county_id/1",
          name:          "African Foundation Baptist",
          group_ext_ids: []
        )
      ]
    end

    let(:package) do
      Orbf::RulesEngine::Package.new(
        code:            :facility,
        kind:            :zone,
        activities:      activities,
        frequency:       :quarterly,
        groupset_ext_id: "zone_groups",
        rules:           [
          Orbf::RulesEngine::Rule.new(
            kind:     :activity,
            formulas: [
              Orbf::RulesEngine::Formula.new(
                "equity_price", "if(quarter_of_year == 1, target * achieved_zone_main_orgunit, 0)"
              )
            ]
          )
        ]
      )
    end

    let(:expected_results) do
      [
        Orbf::RulesEngine::Variable.with(
          key:            "facility_act1_equity_price_for_1_and_2016q1",
          period:         "2016Q1",
          expression:     "if(1 == 1, facility_act1_target_for_1_and_2016q1 * facility_act1_achieved_zone_main_orgunit_for_1_and_2016q1, 0)",
          type:           "activity_rule",
          state:          "equity_price",
          activity_code:  "act1",
          orgunit_ext_id: "1",
          formula:        package.rules.first.formulas.first,
          package:        package,
          payment_rule:   nil
        )
      ]
    end
    it "substitute decision tables variables" do
      expect(action).to eq_vars(expected_results)
    end
  end
end
