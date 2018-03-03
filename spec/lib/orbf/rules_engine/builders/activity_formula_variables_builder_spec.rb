
RSpec.describe Orbf::RulesEngine::ActivityFormulaVariablesBuilder do
  let(:activities) do
    [
      Orbf::RulesEngine::Activity.with(
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

  let(:project) { Orbf::RulesEngine::Project.new(packages: [package]) }

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

  let(:basic_formula) { package.formula.last }

  let(:formula_with_span) { package.formula.first }

  let(:expected_results) do
    [
      Orbf::RulesEngine::Variable.with(
        key:            "#{package.code}_act1_percent_achieved_for_1_and_2016q1",
        period:         "2016Q1",
        expression:     "#{package.code}_act1_active_for_1_and_2016q1 * safe_div(#{package.code}_act1_achieved_for_1_and_2016q1,sum(#{package.code}_act1_achieved_for_1_and_201501,#{package.code}_act1_achieved_for_1_and_201502,#{package.code}_act1_achieved_for_1_and_201503)",
        type:           :activity_rule,
        state:          "percent_achieved",
        activity_code:  "act1",
        orgunit_ext_id: "1",
        formula:        package.rules.first.formulas.first,
        package:        package
      ),

      Orbf::RulesEngine::Variable.with(
        key:            "#{package.code}_act1_allowed_for_1_and_2016q1",
        period:         "2016Q1",
        expression:     "if (#{package.code}_act1_percent_achieved_for_1_and_2016q1 < 0.75, 0, #{package.code}_act1_percent_achieved_for_1_and_2016q1)",
        type:           :activity_rule,
        state:          "allowed",
        activity_code:  "act1",
        orgunit_ext_id: "1",
        formula:        project.packages.first.rules.first.formulas.last,
        package:        package
      )
    ]
  end

  it "does the susbstitions of spans and instantiate other states for activity variable" do
    results = described_class.new(project.packages.first, orgunits, "2016Q1").to_variables
    expect(results).to eq_vars(expected_results)
  end

  describe "Spans substitutions" do
    let(:activities) do
      [
        Orbf::RulesEngine::Activity.with(
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
          expression:     "act1_price_for_2016q1/2",
          type:           :activity_rule,
          state:          "half_price",
          activity_code:  "act1",
          orgunit_ext_id: "1",
          formula:        package.rules.first.formulas.first,
          package:        package
        )
      ]
    end

    it "does the susbstitions of spans and instantiate other states for activity variable" do
      results = described_class.new(project.packages.first, orgunits, "2016Q1").to_variables
      expect(results).to eq_vars(expected_results)
    end
  end
end
