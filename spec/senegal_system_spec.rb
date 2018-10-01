
RSpec.describe "Senegal System" do
  let(:period) { "2016Q1" }

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
      ),
      Orbf::RulesEngine::OrgUnitGroup.with(
        ext_id: "primary",
        code:   "primary",
        name:   "Primary"
      ),
      Orbf::RulesEngine::OrgUnitGroup.with(
        ext_id: "cs",
        code:   "cs",
        name:   "cs"
      )
    ]
  end

  let(:orgunits) do
    [
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "1",
        path:          "country_id/county_id/1",
        name:          "ABCD",
        group_ext_ids: %w[primary cs contracgroup1]
      ),
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "2",
        path:          "country_id/county_id/2",
        name:          "EFGH",
        group_ext_ids: %w[cs contracgroup1]
      )
    ]
  end

  let(:states) { %i[claimed verified validated] }

  let(:activities) do
    (1..2).map do |activity_index|
      activity_code = "act#{activity_index}"
      activity_states = states.map do |state|
        Orbf::RulesEngine::ActivityState.new_data_element(
          state:  state,
          ext_id: "dhis2_#{activity_code}_#{state}",
          name:   "#{activity_code}_#{state}"
        )
      end
      activity_states.push(
        Orbf::RulesEngine::ActivityState.new_constant(
          state:   "tarif",
          name:    "#{activity_code}_tarif",
          formula: (10 * activity_index).to_s
        )
      )
      Orbf::RulesEngine::Activity.with(
        name:            activity_code,
        activity_code:   activity_code,
        activity_states: activity_states
      )
    end
  end

  let(:quantity_package) do
    Orbf::RulesEngine::Package.new(
      code:                   :quantity,
      kind:                   :single,
      frequency:              :monthly,
      org_unit_group_ext_ids: %w[cs],
      groupset_ext_id:        nil,
      activities:             activities,
      rules:                  [
        Orbf::RulesEngine::Rule.new(
          kind:     :activity,
          formulas: [
            build_activity_formula(
              "difference_percentage ", "IF(verified_is_null=1,0,safe_div(ABS(claimed-verified), verified)*100.0)"
            ),
            build_activity_formula(
              "qtt_percent_rule", "IF(difference_percentage<=5,validated,0)"
            ),
            build_activity_formula(
              "monthly_sanction", "IF(difference_percentage>5,1,0)"
            ),
            build_activity_formula(
              "quarterly_sanction", "IF(SUM(%{monthly_sanction_current_quarter_values}) > 0,0,1)"
            ),
            build_activity_formula(
              "amount ", "qtt_percent_rule * quarterly_sanction"
            )
          ]
        ),
        Orbf::RulesEngine::Rule.new(
          kind:     :package,
          formulas: [
            build_formula(
              "quantity_total_ps", "SUM(%{amount_values})"
            )
          ]
        )
      ]
    )
  end

  let(:project) do
    Orbf::RulesEngine::Project.new(
      packages:      [
        quantity_package
      ],
      payment_rules: []
    )
  end

  let(:dhis2_values) do
    Dhis2ValuesHelper.ensure_valid([
                                     { "dataElement" => "dhis2_act1_verified", "categoryOptionCombo" => "default", "value" => "33", "period" => "201601", "orgUnit" => "1" },
                                     { "dataElement" => "dhis2_act2_validated", "categoryOptionCombo" => "default", "value" => "80", "period" => "201601", "orgUnit" => "1" },
                                     { "dataElement" => "dhis2_act1_claimed", "categoryOptionCombo" => "default", "value" => "40", "period" => "201601", "orgUnit" => "1" },
                                     { "dataElement" => "dhis2_act1_claimed", "categoryOptionCombo" => "default", "value" => "12", "period" => "201601", "orgUnit" => "2" },
                                     { "dataElement" => "dhis2_act2_verified", "categoryOptionCombo" => "default", "value" => "92", "period" => "201601", "orgUnit" => "2" },
                                     { "dataElement" => "dhis2_act1_verified", "categoryOptionCombo" => "default", "value" => "31", "period" => "201601", "orgUnit" => "2" },
                                     { "dataElement" => "dhis2_act1_validated", "categoryOptionCombo" => "default", "value" => "37", "period" => "201601", "orgUnit" => "2" }
                                   ])
  end

  let(:solver) do
    build_solver(orgunits, dhis2_values)
  end

  let(:expected_problem) { JSON.parse(fixture_content(:rules_engine, "senegal_problem.json")) }
  it "should build problem based on variables" do
    solver = build_solver(orgunits, dhis2_values)
    problem = solver.build_problem
    puts JSON.pretty_generate(problem) if problem != expected_problem
    expect(problem).to eq(expected_problem)
  end

  it "should solve equations" do
    solver.solve!

    expect(solver.solution["quantity_act1_difference_percentage_for_1_and_201601"]).to be_within(0.001).of(21.212)

    Orbf::RulesEngine::InvoiceCliPrinter.new(solver.variables, solver.solution).print
  end

  def build_solver(orgunits, dhis2_values)
    pyramid = Orbf::RulesEngine::Pyramid.new(
      org_units:          orgunits,
      org_unit_groups:    orgunit_groups,
      org_unit_groupsets: [groupset]
    )

    package_arguments = Orbf::RulesEngine::ResolveArguments.new(
      project:          project,
      pyramid:          pyramid,
      orgunit_ext_id:   orgunits[0].ext_id,
      invoicing_period: "2016Q1"
    ).call

    package_vars = Orbf::RulesEngine::ActivityVariablesBuilder.to_variables(package_arguments, dhis2_values)

    Orbf::RulesEngine::SolverFactory.new(
      project,
      package_arguments,
      package_vars,
      period
    ).new_solver
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
