RSpec::Matchers.define :eq_vars do |expected|
  match do |actual|
    actual == expected
  end

  failure_message do |actual|
    got_equations = actual.map do |r|
      ["got : #{r.key}  = #{r.expression}"]
    end

    expected_equations = expected.map do |r|
      ["expected : #{r.key}  = #{r.expression}"]
    end
    (got_equations + expected_equations).join("\n")
  end
end
