RSpec.describe Orbf::RulesEngine::Dhis2IndexedValues do
  subject do
    described_class.new(in_dhis2_values)
  end
  let(:valid_period) { "2016Q1" }
  let(:invalid_period) { "9999Q1" }
  let(:in_dhis2_values) do
    [
      { "dataElement" => "xtVtnuWBBLB", "categoryOptionCombo" => "default",
        "value" => "34", "period" => "2016Q1", "orgUnit" => "1" },
      { "dataElement" => "dhjgLt7EYmu", "categoryOptionCombo" => "coc1",
        "value" => "33", "period" => "2016Q1", "orgUnit" => "1" },
      { "dataElement" => "dhjgLt7EYmu", "categoryOptionCombo" => "coc2",
        "value" => "33", "period" => "2016Q1", "orgUnit" => "1" },
      { "dataElement" => "xtVtnuWBBLB", "categoryOptionCombo" => "default",
        "value" => "24", "period" => "2016Q1", "orgUnit" => "2" },
      { "dataElement" => "dhjgLt7EYmu", "categoryOptionCombo" => "se1qWfbtkmx",
        "value" => "3", "period" => "2016Q1", "orgUnit" => "2" }
    ]
  end

  it "indexes DHIS2 Values by given attributes" do
    expected_lookup_values(
      given:    [valid_period, "1", "xtVtnuWBBLB", "default"],
      expected: [in_dhis2_values[0]]
    )
  end

  it "indexes DHIS2 Values by given attributes" do
    expected_lookup_values(
      given:    [valid_period, "1", "dhjgLt7EYmu", "coc2"],
      expected: [in_dhis2_values[2]]
    )
  end

  it "indexes DHIS2 Values by given attributes" do
    expected_lookup_values(
      given:    [valid_period, "1", "dhjgLt7EYmu", nil],
      expected: [in_dhis2_values[1], in_dhis2_values[2]]
    )
  end

  it "indexes DHIS2 Values by given attributes" do
    expected_lookup_values(
      given:    [invalid_period, "1", "dhjgLt7EYmu", nil],
      expected: []
    )
  end

  def expected_lookup_values(given:, expected:)
    indexed_values = subject.lookup_values(*given)
    expect(indexed_values).to eq(expected)
  end
end
