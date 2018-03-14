RSpec.describe "eq_vars" do
  let(:defaults) do
    {
      period:         "2016Q1",
      key:            "key",
      expression:     "expression",
      state:          "state_code",
      activity_code:  "activity.activity_code",
      type:           "contract",
      orgunit_ext_id: "ref_orgunit.ext_id",
      formula:        nil,
      package:        "package"
    }
  end
  def build_variable(args = {})
    values = defaults.merge(args)
    Orbf::RulesEngine::Variable.with(values)
  end

  it "verify equality" do
    expect([build_variable]).to eq_vars([build_variable])
  end

  describe "fail_message" do
    let(:expected_messages) do
      [
        "-------------------- Common keys",
        "*** OK key",
        "    got :      key = expression, contract, 2016Q1, state_code, activity.activity_code, ref_orgunit.ext_id, true, true, true",
        "    expected:  key = expression, contract, 2016Q1, state_code, activity.activity_code, ref_orgunit.ext_id",
        "",
        "-------------------- missing expected keys",
        "missing",
        "-------------------- non expected keys",
        "extra",
        "-------------------- ALL got and all expected",
        "got      :  key = expression, contract, 2016Q1, state_code, activity.activity_code, ref_orgunit.ext_id",
        "got      :  extra = expression, contract, 2016Q1, state_code, activity.activity_code, ref_orgunit.ext_id",
        "expected :  missing = expression, contract, 2016Q1, state_code, activity.activity_code, ref_orgunit.ext_id",
        "expected :  key = expression, contract, 2016Q1, state_code, activity.activity_code, ref_orgunit.ext_id"
      ]
    end

    it "provide helpfull fail message" do
      begin
        expect([build_variable, build_variable(key: "extra")]).to eq_vars([build_variable(key: "missing"), build_variable])
        raise("should have thrown an exception")
      rescue RSpec::Expectations::ExpectationNotMetError => e
        # I know there's a expect to raise_error but error message were unusable on failure
        # so went on comparing line by line
        e.message.split("\n").each_with_index do |got_line, index|
          expect(got_line).to eq expected_messages[index]
        end
      end
    end
  end
end
