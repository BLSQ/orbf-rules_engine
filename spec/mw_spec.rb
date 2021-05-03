
RSpec.describe "Malawi System" do
  let(:period) { "2016Q1" }

  let(:groupset) do
    Orbf::RulesEngine::OrgUnitGroupset.with(
      name:          "contracts",
      ext_id:        "contracts_groupset_ext_id",
      group_ext_ids: ["contracgroup1"],
      code:          "contracts"
    )
  end

  let(:public_private_groupset) do
    Orbf::RulesEngine::OrgUnitGroupset.with(
      name:          "public_private",
      ext_id:        "public_private_groupset_ext_id",
      group_ext_ids: %w[public private],
      code:          "public_private"
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
      ),
      Orbf::RulesEngine::OrgUnitGroup.with(
        ext_id: "public",
        code:   "public",
        name:   "public"
      ),
      Orbf::RulesEngine::OrgUnitGroup.with(
        ext_id: "private",
        code:   "private",
        name:   "private"
      )
    ]
  end

  let(:orgunits) do
    [
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "1",
        path:          "country_id/county_id/1",
        name:          "ABCD",
        group_ext_ids: %w[primary cs contracgroup1 public]
      ),
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "2",
        path:          "country_id/county_id/2",
        name:          "EFGH",
        group_ext_ids: %w[cs contracgroup1 public]
      ),
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        "3",
        path:          "country_id/county_id/3",
        name:          "EFGH",
        group_ext_ids: %w[cs contracgroup1 private]
      )
    ]
  end

  let(:activities) do
    [
      Orbf::RulesEngine::Activity.with(
        name:            "dhmt_1",
        activity_code:   "dhmt_1",
        activity_states: [
          Orbf::RulesEngine::ActivityState.new_constant(
            state:   "activity_type",
            name:    "dhmt_1_price",
            formula: "1"
          ),
          Orbf::RulesEngine::ActivityState.new_data_element(
            state:  "validated",
            name:   "dhmt_1_price",
            ext_id: "ext_validated_dhmt_1",
            origin: "dataValueSets"
          )
        ]
      ),
      Orbf::RulesEngine::Activity.with(
        name:            "dhmt_2",
        activity_code:   "dhmt_2",
        activity_states: [
          Orbf::RulesEngine::ActivityState.new_constant(
            state:   "activity_type",
            name:    "dhmt_2_activity_type",
            formula: "2"
          ),
          Orbf::RulesEngine::ActivityState.new_constant(
            state:   "price",
            name:    "dhmt_2_price",
            formula: "2000"
          ),
          Orbf::RulesEngine::ActivityState.new_data_element(
            state:  "validated",
            name:   "dhmt_2_price",
            ext_id: "ext_validated_dhmt_2",
            origin: "dataValueSets"
          )
        ]
      )
    ]
  end

  let(:subcontract_package) do
    Orbf::RulesEngine::Package.new(
      code:                   :quantity_subcontract,
      kind:                   :subcontract,
      frequency:              :monthly,
      main_org_unit_group_ext_ids: ["primary"],
      groupset_ext_id:        "contracts_groupset_ext_id",
      activities:             activities,
      rules:                  [
        Orbf::RulesEngine::Rule.new(
          kind:            :entities_aggregation,
          formulas:        [
            build_activity_formula(
              "fosa_caped_amount", "validated * price",
              "aggrega amount"
            )
          ],
          decision_tables: [
            Orbf::RulesEngine::DecisionTable.new(%(in:activity_code,in:groupset_code_public_private,out:sum_if
                dhmt_1,public,false
                dhmt_2,private,true
                *,*,true
              ), start_period: nil, end_period: nil)
          ]
        ),
        Orbf::RulesEngine::Rule.new(
          kind:     :activity,
          formulas: [
            build_activity_formula(
              "dhmt_verified_price", "if(activity_type=1, sum(%{fosa_caped_amount_values}), " \
                                     "if(activity_type=2, safe_div(sum(%{validated_previous_year_same_quarter_values}), org_units_sum_if_count), 0))",
              "Activity amount"
            ),
            build_activity_formula(
              "dhmt_average_amount", "(validated * price) / org_units_count",
              "average amount"
            )
          ]
        ),
        Orbf::RulesEngine::Rule.new(
          kind:     :package,
          formulas: [
            build_formula(
              "fosa_package_total", "SUM(%{dhmt_verified_price_values})"
            )
          ]
        )
      ]
    )
  end

  let(:project) do
    Orbf::RulesEngine::Project.new(
      packages:      [
        subcontract_package
      ],
      payment_rules: [
      ]
    )
  end

  let(:dhis2_values) { [] }

  let(:solver) do
    build_solver(orgunits, dhis2_values)
  end

  let(:expected_problem) { JSON.parse(fixture_content(:rules_engine, "mw_problem.json")) }
  it "should build problem based on variables" do
    solver = build_solver(orgunits, dhis2_values)
    problem = solver.build_problem
    puts JSON.pretty_generate(problem) if problem != expected_problem
    expect(problem).to eq(expected_problem)
  end

  it "should solve equations" do
    solution = solver.solve!

    Orbf::RulesEngine::InvoiceCliPrinter.new(solver.variables, solver.solution).print
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

  def build_solver(orgunits, dhis2_values)
    pyramid = Orbf::RulesEngine::Pyramid.new(
      org_units:          orgunits,
      org_unit_groups:    orgunit_groups,
      org_unit_groupsets: [groupset, public_private_groupset]
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
end
