RSpec.describe Orbf::RulesEngine::DecisionTable do
  let(:table) do
    described_class.new(%(in:level_1,in:level_2,in:level_3,out:equity_bonus
         belgium,*,*,11
         belgium,namur,*,1
         belgium,brussel,*,2
         belgium,brussel,kk,2
       ), start_period: nil, end_period: nil)
  end

  describe "#to_s" do
    it "help debugging" do
      expect(table.to_s).to eq table.inspect
    end
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

  describe "#match_period?" do
    let(:table_with_periods) do
      described_class.new(%(in:level_1,in:level_2,in:level_3,out:equity_bonus
         belgium,*,*,11
         belgium,namur,*,1
         belgium,brussel,*,2
         belgium,brussel,kk,2
       ), start_period: "2020Q1", end_period: "2020Q3")
    end

    it "matches if no start/end then" do 
      expect(table.match_period?("2020Q1")).to be true
    end

    it "starts inclusive" do 
      expect(table_with_periods.match_period?("2020Q1")).to be true
    end

    it "ends inclusive" do 
      expect(table_with_periods.match_period?("2020Q3")).to be true
    end

    it "handle what's in between" do 
      expect(table_with_periods.match_period?("2020Q2")).to be true
    end

    it "doesn't match just before" do 
      expect(table_with_periods.match_period?("2019Q4")).to be false
    end

    it "doesn't match just after" do 
      expect(table_with_periods.match_period?("2020Q4")).to be false
    end
  end
end
