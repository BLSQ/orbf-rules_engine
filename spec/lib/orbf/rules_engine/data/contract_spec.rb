RSpec.describe Orbf::RulesEngine::Contract do
  let(:calendar) { ::Orbf::RulesEngine::GregorianCalendar.new }
  let(:contract) do
    field_values = {
      "id"                  => "GPAGzdsLDTP",
      "org_unit"            => {
        "id"   => "cLc2uthCRfm",
        "name" => "kl Kinguendi Centre de Santé",
        "path" => "/pL5A7C1at1M/BmKjwqc6BEw/DkK8tVZ6xfJ/z6sJvc6NR59/cLc2uthCRfm"
      },
      "date"                => "2018-06-01T00:00:00.000+0000",
      "contract_start_date" => "2018-07-01",
      "contract_end_date"   => "2021-12-31",
      "contract_type"       => "PMA"
    }
    Orbf::RulesEngine::Contract.new(field_values, calendar)
  end

  describe "#to_s, inspect and to_h" do
    it "works" do
      contract.to_s
      contract.inspect

      expect(contract.to_h).to eq({
                                    id:            "GPAGzdsLDTP",
                                    from_period:   "201807",
                                    end_period:    "202112",
                                    field_values:  { "contract_end_date" => "2021-12-31", "contract_start_date" => "2018-07-01", "contract_type" => "PMA", "date" => "2018-06-01T00:00:00.000+0000", "id" => "GPAGzdsLDTP", "org_unit" => { "id" => "cLc2uthCRfm", "name" => "kl Kinguendi Centre de Santé", "path" => "/pL5A7C1at1M/BmKjwqc6BEw/DkK8tVZ6xfJ/z6sJvc6NR59/cLc2uthCRfm" } },
                                    org_unit_id:   "cLc2uthCRfm",
                                    org_unit_name: "kl Kinguendi Centre de Santé"

                                  })
    end
  end

  describe "#codes" do
    it "works" do
      expect(contract.codes).to eq(["pma"])
    end
  end

  describe "#start_period && #end_period" do
    it "turns dates into dhis2 start/end monthly periods" do
      expect(contract.start_period).to eq("201807")
      expect(contract.end_period).to eq("202112")
    end
  end

  describe "#match_period?" do
    it "matches month periods" do
      expect(contract.match_period?("201804")).to be false
      expect(contract.match_period?("201805")).to be false
      expect(contract.match_period?("201806")).to be false
      expect(contract.match_period?("201807")).to be true

      expect(contract.match_period?("201901")).to be true
      expect(contract.match_period?("202112")).to be true

      expect(contract.match_period?("202201")).to be false
      expect(contract.match_period?("202202")).to be false
    end

    it "matches quarter periods" do
      expect(contract.match_period?("2018Q2")).to be false

      expect(contract.match_period?("2018Q3")).to be true
      expect(contract.match_period?("2019Q1")).to be true
      expect(contract.match_period?("2021Q4")).to be true

      expect(contract.match_period?("2022Q1")).to be false
    end
  end

  describe "#overlaps?" do
    def test_overlaps(other_start, other_end, expected)
      other_contract = build_contract(other_start, other_end)
      message = "contract #{contract.start_period} #{contract.end_period} vs #{other_contract.start_period} #{other_contract.end_period}"
      # should be symetric
      expect(contract.overlaps?(other_contract)).to eq(expected), message
      expect(other_contract.overlaps?(contract)).to eq(expected), message
    end

    it "doesn't overlaps with it self" do
      expect(contract.overlaps?(contract)).to be false
    end

    it "overlaps exact start end" do
      test_overlaps("2017-01", "2021-12", true)
    end

    it "overlaps inside" do
      test_overlaps("2019-01", "2019-03", true)
    end

    it "overlaps a bit in the end" do
      test_overlaps("2021-12", "2022-05", true)
    end

    it "overlaps a bit at the start" do
      test_overlaps("2021-12", "2022-05", true)
    end

    it "do not overlaps at the beginning" do
      test_overlaps("2017-01", "2018-06", false)
    end

    it "do not overlaps at the end" do
      test_overlaps("2022-01", "2022-05", false)
    end
  end

  describe "#overlappings" do
    it "return pair of overlapping contracts per orgunit" do
      other_contract = build_contract("2021-12", "2022-05")
      contracts = [
        contract,
        other_contract
      ]
      overlappings = Orbf::RulesEngine::Contract.overlappings(contracts)

      expect(overlappings).to eq([[
                                   [contract, other_contract],
                                   [other_contract, contract]
                                 ]])
    end

    it "return empty if no overlappings" do
      contracts = [
        contract,
        build_contract("2022-01", "2022-05")
      ]
      expect(Orbf::RulesEngine::Contract.overlappings(contracts)).to eq([])
    end
  end

  describe "#initialize" do
    describe "#validate!" do
      describe "missing orgunit" do
        it "raises ContractValidationException with custom message on missing orgunit" do
          field_values = {
            "id"                  => "GPAGzdsLDTP",
            "date"                => "2018-06-01T00:00:00.000+0000",
            "contract_end_date"   => "2021-12-31",
            "contract_type"       => "PMA"
          }
      
          missing_attrs = "contract_start_date, org_unit"
          
          expect { Orbf::RulesEngine::Contract.new(field_values, calendar) }.to raise_error(Orbf::RulesEngine::ContractValidationException)
          expect { Orbf::RulesEngine::Contract.new(field_values, calendar) }.to raise_error.with_message(/#{missing_attrs}/)
        end
      end

      describe "missing orgunit attributes" do
        it "raises ContractValidationException with custom message on missing orgunit attributes" do
          field_values = {
            "id"                  => "GPAGzdsLDTP",
            "org_unit"            => {
              "id"   => "cLc2uthCRfm",
              "path" => "/pL5A7C1at1M/BmKjwqc6BEw/DkK8tVZ6xfJ/z6sJvc6NR59/cLc2uthCRfm"
            },
            "date"                => "2018-06-01T00:00:00.000+0000",
            "contract_start_date" => "2018-07-01",
            "contract_type"       => "PMA"
          }
      
          missing_attrs = "contract_end_date, org_unit_name"
          relevant_org_unit_id = "cLc2uthCRfm"
          
          expect { Orbf::RulesEngine::Contract.new(field_values, calendar) }.to raise_error(Orbf::RulesEngine::ContractValidationException)
          expect { Orbf::RulesEngine::Contract.new(field_values, calendar) }.to raise_error.with_message(/#{missing_attrs}/)
          expect { Orbf::RulesEngine::Contract.new(field_values, calendar) }.to raise_error.with_message(/#{relevant_org_unit_id}/)
        end

        it "raises ContractValidationException with custom message on missing orgunit attributes" do
          field_values = {
            "id"                  => "GPAGzdsLDTP",
            "org_unit"            => {
              "id"   => "cLc2uthCRfm",
              "name" => nil,
              "path" => "/pL5A7C1at1M/BmKjwqc6BEw/DkK8tVZ6xfJ/z6sJvc6NR59/cLc2uthCRfm"
            },
            "date"                => "2018-06-01T00:00:00.000+0000",
            "contract_start_date" => "2018-07-01",
            "contract_type"       => "PMA"
          }
      
          missing_attrs = "contract_end_date, org_unit_name"
          relevant_org_unit_id = "cLc2uthCRfm"
          
          expect { Orbf::RulesEngine::Contract.new(field_values, calendar) }.to raise_error(Orbf::RulesEngine::ContractValidationException)
          expect { Orbf::RulesEngine::Contract.new(field_values, calendar) }.to raise_error.with_message(/#{missing_attrs}/)
          expect { Orbf::RulesEngine::Contract.new(field_values, calendar) }.to raise_error.with_message(/#{relevant_org_unit_id}/)
        end
      end
  
      describe "missing attributes, existing orgunit" do
        it "raises ContractValidationException with custom message on missing attributes, relevant orgunit" do
          
          field_values = {
            "id"                  => "GPAGzdsLDTP",
            "org_unit"            => {
              "id"   => "cLc2uthCRfm",
              "name" => "kl Kinguendi Centre de Santé",
              "path" => "/pL5A7C1at1M/BmKjwqc6BEw/DkK8tVZ6xfJ/z6sJvc6NR59/cLc2uthCRfm"
            },
            "date"                => "2018-06-01T00:00:00.000+0000",
            "contract_start_date" => "2018-07-01",
            "contract_type"       => "PMA"
          }
    
          missing_attrs = "contract_end_date"
          relevant_org_unit = "kl Kinguendi Centre de Santé"
            
          expect { Orbf::RulesEngine::Contract.new(field_values, calendar) }.to raise_error(Orbf::RulesEngine::ContractValidationException)
          expect { Orbf::RulesEngine::Contract.new(field_values, calendar) }.to raise_error.with_message(/#{missing_attrs}/)
          expect { Orbf::RulesEngine::Contract.new(field_values, calendar) }.to raise_error.with_message(/#{relevant_org_unit}/)
        end
      end

      describe "attributes nil or blank" do
        it "raises ContractValidationException with custom message on missing attributes, relevant orgunit" do
          field_values = {
            "id"                  => "GPAGzdsLDTP",
            "org_unit"            => {
              "id"   => "cLc2uthCRfm",
              "name" => "kl Kinguendi Centre de Santé",
              "path" => "/pL5A7C1at1M/BmKjwqc6BEw/DkK8tVZ6xfJ/z6sJvc6NR59/cLc2uthCRfm"
            },
            "date"                => "2018-06-01T00:00:00.000+0000",
            "contract_start_date" => "2018-07-01",
            "contract_end_date"   => "",
            "contract_type"       => "PMA"
          }
          missing_attrs = "contract_end_date"
          relevant_org_unit = "kl Kinguendi Centre de Santé"

          expect { Orbf::RulesEngine::Contract.new(field_values, calendar) }.to raise_error(Orbf::RulesEngine::ContractValidationException)
          expect { Orbf::RulesEngine::Contract.new(field_values, calendar) }.to raise_error.with_message(/#{missing_attrs}/)
          expect { Orbf::RulesEngine::Contract.new(field_values, calendar) }.to raise_error.with_message(/#{relevant_org_unit}/)
        end
      end
    end
    
  end

  def build_contract(start_month, end_month)
    field_values = {
      "id"                  => "OTHERID",
      "org_unit"            => {
        "id"   => "cLc2uthCRfm",
        "name" => "kl Kinguendi Centre de Santé",
        "path" => "/pL5A7C1at1M/BmKjwqc6BEw/DkK8tVZ6xfJ/z6sJvc6NR59/cLc2uthCRfm"
      },
      "date"                => "2018-06-01T00:00:00.000+0000",
      "contract_start_date" => "#{start_month}-01",
      "contract_end_date"   => "#{end_month}-31",
      "contract_type"       => "PMA"
    }
    Orbf::RulesEngine::Contract.new(field_values, calendar)
  end
end
