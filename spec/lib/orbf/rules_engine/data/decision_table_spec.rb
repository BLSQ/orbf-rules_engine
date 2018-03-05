RSpec.describe Orbf::RulesEngine::DecisionTable do
  let(:table) do
    described_class.new(%(in:level_1,in:level_2,in:level_3,out:equity_bonus
         belgium,*,*,11
         belgium,namur,*,1
         belgium,brussel,*,2
         belgium,brussel,kk,2
       ))
  end

  describe "#headers" do
    it "get in headers" do
      expect(table.headers(:in)).to eq %w[level_1 level_2 level_3]
    end
    it "get out headers" do
      expect(table.headers(:out)).to eq ["equity_bonus"]
    end

    it "get all headers" do
      expect(table.headers).to eq ["in:level_1", "in:level_2", "in:level_3", "out:equity_bonus"]
    end
  end

  describe "#find" do
    it "locate best rule for kk" do
      expect(table.find(level_1: "belgium", level_2: "namur", level_3: "kk")["equity_bonus"]).to eq "1"
    end

    it "locate best rule for namur" do
      expect(table.find(level_1: "belgium", level_2: "namur")["equity_bonus"]).to eq "1"
    end

    it "locate best rule for brussel" do
      expect(table.find(level_1: "belgium", level_2: "brussel")["equity_bonus"]).to eq "2"
    end

    it "locate best rule for the rest of belgium" do
      expect(table.find("level_1" => "belgium", "level_2" => "houtsiplou")["equity_bonus"]).to eq "11"
    end

    it "return nil if none matching" do
      expect(table.find(level_1: "holland", level_2: "houtsiplou")).to be nil
    end
  end
end
