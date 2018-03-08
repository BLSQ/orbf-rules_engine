RSpec::Matchers.define :eq_vars do |expected|
  match do |actual|
    actual == expected
  end

  def var_to_log(r)
    " #{r.key} = #{r.expression}, #{r.type}, #{r.period}, #{r.state}, #{r.activity_code}, #{r.orgunit_ext_id}"
  end

  failure_message do |actual|
    seperator = "-------------------- "
    actual_by_keys = actual.group_by(&:key)
    expected_by_keys = expected.group_by(&:key)

    messages = [seperator + "Common keys"]
    (actual_by_keys.keys & expected_by_keys.keys).each do |common_key|
      act = actual_by_keys[common_key].first
      exp = expected_by_keys[common_key].first
      messages.push [
        "*** #{act == exp ? 'OK' : 'KO!!!'} #{common_key}",
        "    got :     " + var_to_log(act) + ", #{act.package == exp.package}, #{act.formula == exp.formula}, #{act == exp}",
        "    expected: " + var_to_log(exp),
        ""
      ].join("\n")
    end
    messages.push(seperator + "missing expected keys")
    messages.push(expected_by_keys.keys - actual_by_keys.keys)
    messages.push(seperator + "non expected keys")
    messages.push(actual_by_keys.keys - expected_by_keys.keys)
    messages.push(seperator + "ALL got and all expected")
    got_equations = actual.map do |r|
      ["got      : #{var_to_log(r)}"]
    end

    expected_equations = expected.map do |r|
      ["expected : #{var_to_log(r)}"]
    end
    (messages + got_equations + expected_equations).join("\n")
  end
end
