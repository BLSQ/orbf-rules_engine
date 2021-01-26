RSpec.describe "Mixed analytics/datavalues System" do
  let(:period) { "2020Q3" }

  let(:indicator_id) { "dNaUIFe7vkY" }

  let(:indicator_dataelement_id) { "zcH4sipFcUr" }
  let(:orgunit_id) { "kH9XaP6eoDo" }

  let(:activities) do
    [
      Orbf::RulesEngine::Activity.with(
        name:            "spread",
        activity_code:   "spread_01",
        activity_states: [
          Orbf::RulesEngine::ActivityState.new_data_element(
            state:                 "raw_indicator_value",
            ext_id:                indicator_dataelement_id,
            name:                  "spread_percentage",
            origin:                "dataValueSets",
            category_combo_ext_id: "default"
          ),
          Orbf::RulesEngine::ActivityState.new_indicator(
            state:      "real_indicator_value",
            ext_id:     indicator_id,
            name:       "spread_to_pay",
            origin:     "analytics",
            expression: '#{' + indicator_dataelement_id + "}"
          )
        ]
      )
    ]
  end

  let(:activities_bis) do
    [
      Orbf::RulesEngine::Activity.with(
        name:            "spread2",
        activity_code:   "spread_02",
        activity_states: [
          Orbf::RulesEngine::ActivityState.new_data_element(
            state:                 "raw_indicator_value",
            ext_id:                indicator_dataelement_id,
            name:                  "spread_percentage",
            origin:                "dataValueSets",
            category_combo_ext_id: "default"
          ),
          Orbf::RulesEngine::ActivityState.new_indicator(
            state:      "real_indicator_value",
            ext_id:     indicator_id,
            name:       "spread_to_pay",
            origin:     "analytics",
            expression: '#{' + indicator_dataelement_id + "}"
          )
        ]
      )
    ]
  end


  let(:project) do
    Orbf::RulesEngine::Project.new(
      dhis2_params: {
        url:      "https://sample",
        user:     "user",
        password: "password"
      },
      packages:     [
        Orbf::RulesEngine::Package.new(
          code:                        :facility_monthly,
          kind:                        :single,
          frequency:                   :monthly,
          main_org_unit_group_ext_ids: ["G_ID_1"],
          activities:                  activities,
          dataset_ext_ids:             ["ds1"],
          rules:                       [
            Orbf::RulesEngine::Rule.new(
              kind:     :activity,
              formulas: [

                build_activity_formula(
                  "de_m", "raw_indicator_value",
                  ""
                ),

                build_activity_formula(
                  "de_m_from_indic", "real_indicator_value",
                  ""
                ),

                build_activity_formula(
                  "de_m_average", "avg(%{real_indicator_value_last_6_months_window_values})",
                  ""
                )
              ]
            )
          ]
        ),

        Orbf::RulesEngine::Package.new(
          code:                        :facility_quarterly,
          kind:                        :single,
          frequency:                   :quarterly,
          main_org_unit_group_ext_ids: ["G_ID_1"],
          activities:                  activities_bis,
          dataset_ext_ids:             ["ds2"],
          rules:                       [
            Orbf::RulesEngine::Rule.new(
              kind:     :activity,
              formulas: [
                build_activity_formula(
                  "de_q", "raw_indicator_value",
                  ""
                ),

                build_activity_formula(
                  "de_q_from_indic", "real_indicator_value",
                  ""
                )
              ]
            )
          ]
        )
      ]
    )
  end

  let(:orgunits_full) do
    [
      Orbf::RulesEngine::OrgUnit.with(
        ext_id:        orgunit_id,
        path:          "path",
        name:          "name",
        group_ext_ids: ["G_ID_1"]
      )
    ]
  end

  let(:org_unit_groups) do
    [
      Orbf::RulesEngine::OrgUnitGroup.with(
        ext_id: "G_ID_1",
        name:   "group health center",
        code:   "health_center"
      )
    ]
  end

  let(:dhis2_values) { [] }

  it "builds problem per category option combo" do
    WebMock::Config.instance.query_values_notation = :flat_array
    all = %w(202002 202003 202004 202005 202006 202007 202008 202009)

    [
      all[0...5],
      all[5..-1] + ["2020Q3"]
    ].each do |periods|
      pe = periods.join(";")
      rows = periods.map do |period|
        if "Q3" == period[0..-2]
          value = "134"
        else
          value = period[-2..-1].to_i*100
        end
        ["dNaUIFe7vkY", "kH9XaP6eoDo", period, value]
      end

      stub_request(:get, "https://sample/api/analytics?dimension=dx:dNaUIFe7vkY&dimension=ou:kH9XaP6eoDo&dimension=pe:#{pe}")
        .to_return(status: 200, body: JSON.pretty_generate(
                     {
                       "height": 3, "rows": rows, "width": 4
                     }
                   ))

    end

    pe = (all + %w(2020 2020July 2020Q3)).sort.map{|s| "period=#{s}" }.join("&")
    stub_request(:get, "https://sample/api/dataValueSets?children=false&dataSet=ds1&dataSet=ds2&orgUnit=path&#{pe}")
      .to_return(status: 200, body: JSON.pretty_generate(
        { "dataValues" => [
          { "dataElement": indicator_dataelement_id, period: "202008", value: "80.0" ,categoryCombo:"Vo4mFUa9rlC"},
          { "dataElement": indicator_dataelement_id, period: "202008", value: "81.0" ,categoryCombo:"PQrXhDwCZBF"},
          { "dataElement": indicator_dataelement_id, period: "202009", value: "90.0" ,categoryCombo:"Vo4mFUa9rlC"},
          { "dataElement": indicator_dataelement_id, period: "202009", value: "91.0" ,categoryCombo:"PQrXhDwCZBF"}
        ] }
      ))

    solved = build_and_solve(orgunits_full, dhis2_values)
    problem = solved.solver.build_problem
    puts JSON.pretty_generate(problem)
    puts JSON.pretty_generate(solved.solver.solution)
  end

  def build_and_solve(orgs, _dhis2_values)
    pyramid = Orbf::RulesEngine::Pyramid.new(
      org_units:          orgs,
      org_unit_groups:    org_unit_groups,
      org_unit_groupsets: []
    )

    fetch_and_solve = Orbf::RulesEngine::FetchAndSolve.new(
      project, orgs[0].ext_id, period,
      pyramid: pyramid
    )

    fetch_and_solve.call

    fetch_and_solve
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
