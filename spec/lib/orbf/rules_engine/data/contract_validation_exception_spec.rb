RSpec.describe Orbf::RulesEngine::ContractValidationException do
  it "has custom messages on missing org unit attributes" do
    missing_attrs = ["contract_start_date"]
    org_unit = { "id" => "cLc2uthCRfm", "name" => nil, "path" => "/pL5A7C1at1M/BmKjwqc6BEw/DkK8tVZ6xfJ/z6sJvc6NR59/cLc2uthCRfm" }
    exception = Orbf::RulesEngine::ContractValidationException.new(missing_attrs, org_unit)
    
    expect(exception.message).to match(/#{"name - missing"}/)
  end

  it "has custom messages on missing org unit" do
    missing_attrs = ["contract_start_date"]
    exception = Orbf::RulesEngine::ContractValidationException.new(missing_attrs, org_unit=nil)
    
    expect(exception.message).to match(/#{"name - missing"}/)
  end

  it "has custom messages on missing attributes" do
    missing_attrs = ["contract_start_date"]
    org_unit = { "id" => "cLc2uthCRfm", "name" => "kl Kinguendi Centre de Santé", "path" => "/pL5A7C1at1M/BmKjwqc6BEw/DkK8tVZ6xfJ/z6sJvc6NR59/cLc2uthCRfm" }
    exception = Orbf::RulesEngine::ContractValidationException.new(missing_attrs, org_unit)
    
    expect(exception.message).to match(/#{"contract_start_date"}/)
  end

  it "has custom messages that contain info about org unit, if available" do
    missing_attrs = ["contract_start_date"]
    org_unit = { "id" => "cLc2uthCRfm", "name" => "kl Kinguendi Centre de Santé", "path" => "/pL5A7C1at1M/BmKjwqc6BEw/DkK8tVZ6xfJ/z6sJvc6NR59/cLc2uthCRfm" }
    exception = Orbf::RulesEngine::ContractValidationException.new(missing_attrs, org_unit)
    
    expect(exception.message).to match(/#{"cLc2uthCRfm"}/)
  end
end