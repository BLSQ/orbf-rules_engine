
RSpec.describe Orbf::RulesEngine::ActivityFormulaValuesExpander do
  let(:period) { "2016" }

  let(:orgunit) do
    Orbf::RulesEngine::OrgUnit.with(
      ext_id:        "1",
      path:          "country_id/county_id/1",
      name:          "African Foundation Baptist",
      group_ext_ids: []
    )
  end

  describe "when no _values pattern to substitute" do
    let(:formula_without_values_pattern) do
      assign_rule(
        Orbf::RulesEngine::Formula.new(
          "allowed",
          "if (percent_achieved < 0.75, 0, percent_achieved)"
        )
      )
    end

    it "return same string when no values pattern" do
      substitued = described_class.new(
        "package_code_tst",
        "activity_code_tst",
        formula_without_values_pattern.expression,
        formula_without_values_pattern.values_dependencies,
        formula_without_values_pattern.rule.kind,
        orgunit,
        period
      ).expand_values
      expect(substitued).to eq "if (percent_achieved < 0.75, 0, percent_achieved)"
    end
  end

  describe "when _previous_year_values" do
    let(:formula_with_values_pattern) do
      assign_rule(
        Orbf::RulesEngine::Formula.new(
          "allowed",
          "sum(%{achieved_previous_year_yearly_values})"
        )
      )
    end
    it "return same string when no values pattern" do
      substitued = described_class.new(
        "package_code_tst",
        "activity_code_tst",
        formula_with_values_pattern.expression,
        formula_with_values_pattern.values_dependencies,
        formula_with_values_pattern.rule.kind,
        orgunit,
        period
      ).expand_values
      expect(substitued).to eq "sum(package_code_tst_activity_code_tst_achieved_for_1_and_2015)"
    end
  end

  def assign_rule(formula)
    formula.tap do |formula|
      formula.rule = OpenStruct.new
      formula.rule.kind = "activity"
    end
  end
end
