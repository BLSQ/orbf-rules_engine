
RSpec.describe "ORBF System" do
  let(:groupset) do
    Orbf::RulesEngine::OrgUnitGroupset.with(
      name:          "contracts",
      ext_id:        "contracts_groupset_ext_id",
      group_ext_ids: ["contracgroup1"],
      code:          "contracts"
    )
  end

  let(:orgunit_groups) do
    [
      Orbf::RulesEngine::OrgUnitGroup.with(
        ext_id: "contracgroup1",
        code:   "contract group 1",
        name:   "contract group 1"
      )
    ]
  end

  let(:orgunits) do
    [
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "1",
        path:          "country_id/county_id/1",
        name:          "ABCD",
        group_ext_ids: %w[contracgroup1]
      ),
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "2",
        path:          "country_id/county_id/2",
        name:          "EFGH",
        group_ext_ids: %w[contracgroup1]
      )
    ]
  end

  let(:states) { %i[budget] }

  let(:activities) do
    activity_code = "act_1"

    [Orbf::RulesEngine::Activity.with(
      name:            activity_code,
      activity_code:   activity_code,
      activity_states: [Orbf::RulesEngine::ActivityState.new_data_element(
        state:  :budget,
        ext_id: "dhis2_#{activity_code}_budget",
        name:   "#{activity_code}_budget"
      )]
    )]
  end

  let(:quantity_package) do
    Orbf::RulesEngine::Package.new(
      code:                   :quantity,
      kind:                   :single,
      frequency:              :quarterly,
      main_org_unit_group_ext_ids: %w[contracgroup1],
      groupset_ext_id:        nil,
      activities:             activities,
      rules:                  [
        Orbf::RulesEngine::Rule.new(
          kind:     :activity,
          formulas: [
            build_activity_formula(
              "quarterly_budget", "budget/4"
            ),
            build_activity_formula(
              "quarterly_budget_parent", "budget_level_1/4"
            )
          ]
        ),
        Orbf::RulesEngine::Rule.new(
          kind:     :package,
          formulas: [
            build_formula(
              "total_quarterly_budget", "MAX(%{quarterly_budget_values})"
            )
          ]
        )
      ]
    )
  end

  let(:project) do
    Orbf::RulesEngine::Project.new(
      packages:     [
        quantity_package
      ],
      dhis2_params: {
        url:      "https://admin:district@play.dhis2.org/2.28",
        user:     "admin",
        password: "district"
      }
    )
  end

  let(:budget2015July) { 33 }
  let(:budget2016July) { 45 }
  let(:country_budget2015July) { 56 }
  let(:country_budget2016July) { 87 }

  let(:dhis2_values) do
    [
      { "dataElement" => "dhis2_act_1_budget", "categoryOptionCombo" => "default", "value" => budget2015July.to_s, "period" => "2015July", "orgUnit" => "1" },
      { "dataElement" => "dhis2_act_1_budget", "categoryOptionCombo" => "default", "value" => budget2016July.to_s, "period" => "2016July", "orgUnit" => "1" },
      { "dataElement" => "dhis2_act_1_budget", "categoryOptionCombo" => "default", "value" => country_budget2015July.to_s, "period" => "2015July", "orgUnit" => "country_id" },
      { "dataElement" => "dhis2_act_1_budget", "categoryOptionCombo" => "default", "value" => country_budget2016July.to_s, "period" => "2016July", "orgUnit" => "country_id" }
    ]
  end
  let(:pyramid) do
    Orbf::RulesEngine::Pyramid.new(
      org_units:          orgunits,
      org_unit_groups:    orgunit_groups,
      org_unit_groupsets: [groupset]
    )
  end

  %w[2015Q3 2015Q4 2016Q1 2016Q2].each do |period|
    it "should select collect values for #{period}" do
      expect_budget(period, budget2015July, country_budget2015July)
    end
  end

  %w[2016Q3 2016Q4 2017Q1 2017Q2].each do |period|
    it "should select collect values for #{period}" do
      expect_budget(period, budget2016July, country_budget2016July)
    end
  end

  %w[2017Q3 2017Q4 2018Q1 2018Q2].each do |period|
    it "should collect 0 value if budget is not set for #{period}" do
      expect_budget(period, 0, 0)
    end
  end

  def expect_budget(period, yearly_budget, country_yearly_budget = 0)
    fetch_and_solve = Orbf::RulesEngine::FetchAndSolve.new(project, "1", period, mock_values: dhis2_values, pyramid: pyramid)
    fetch_and_solve.call
    expect(fetch_and_solve.exported_values).to eq(
      [{ dataElement: "dhis2_dataelement_id_quarterly_budget act_1",
         orgUnit:     "1",
         period:      period,
         value:       Orbf::RulesEngine::ValueFormatter.format(yearly_budget.to_f / 4),
         comment:     "quantity_act_1_quarterly_budget_for_1_and_#{period.downcase}" },
       { dataElement: "dhis2_dataelement_id_quarterly_budget_parent act_1",
         orgUnit:     "1",
         period:      period,
         value:       Orbf::RulesEngine::ValueFormatter.format(country_yearly_budget.to_f / 4),
         comment:     "quantity_act_1_quarterly_budget_parent_for_1_and_#{period.downcase}" },
       { dataElement: "dhis2_dataelement_id_total_quarterly_budget",
         orgUnit:     "1",
         period:      period,
         value:       Orbf::RulesEngine::ValueFormatter.format(yearly_budget.to_f / 4),
         comment:     "quantity_total_quarterly_budget_for_1_and_#{period.downcase}" }]
    )
  end

  def build_formula(code, expression, comment = nil)
    Orbf::RulesEngine::Formula.new(code, expression, comment, single_mapping: "dhis2_dataelement_id_#{code}")
  end

  def build_activity_formula(code, expression, comment = nil)
    Orbf::RulesEngine::Formula.new(code, expression, comment, activity_mappings: build_activity_mappings(code))
  end

  def build_activity_mappings(formula_code)
    activities.each_with_object({}) do |activity, mappings|
      mappings[activity.activity_code] = "dhis2_dataelement_id_#{formula_code} #{activity.activity_code}"
    end
  end
end
