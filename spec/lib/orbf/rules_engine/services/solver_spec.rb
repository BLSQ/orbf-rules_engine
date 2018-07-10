RSpec.describe Orbf::RulesEngine::Solver do
  def build_variable(key, expression = "10")
    Orbf::RulesEngine::Variable.with(
      period:         "2016",
      key:            key,
      expression:     expression,
      state:          "achieved",
      activity_code:  "act1",
      type:           "contract",
      orgunit_ext_id: "district_orgunit1.ext_id",
      formula:        nil,
      package:        nil,
      payment_rule:   nil
    )
  end

  let(:solver) { described_class.new }

  it "raise error on duplicate variables" do
    solver.register_variables([build_variable("key1")])
    expect do
      solver.register_variables([build_variable("key1", "duuu")])
    end.to raise_error(/Duplicates for key1=/)
  end

  it "logs Dentaku::ArgumentError" do
    expect do
      solver.register_variables(
        [
          build_variable("key1", "10 - nil_key"),
          build_variable("nil_key", nil)
        ]
      )
      solver.solve!
    end.to raise_error(
      Hesabu::Error,
      "In equation nil_key Unexpected end of expression nil_key := "
    )
  end

  it "throws error when equations don't match" do
    solver.register_variables(
      [
        build_variable("key1", "10"),
        build_variable("key2", "key_missing")
      ]
    )
    expect { solver.solve! }.to raise_error(
      Hesabu::Error,
      "In equation key2 No parameter 'key_missing' found. key2 := key_missing"
    )
  end
end
