
RSpec.describe Orbf::RulesEngine::CalculatorFactory do
  let(:calculator) { described_class.build }

  describe "support avg function" do
    it "solve " do
      solution = calculator.solve("myavg" => "AVG(1,3,9)")
      expect(solution["myavg"]).to eq(4.333333333333333)
    end
  end

  describe "support score table function" do
    [
      [9, 1],
      [10, 2],
      [89.9, 2],
      [99, 3]
    ].each do |testcase|
      it "resolve #{testcase.first} according to score table as value #{testcase.last}" do
        expect(solve_score_table(testcase.first)).to eq(testcase.last)
      end
    end

    def solve_score_table(value)
      solution = calculator.solve(
        "my_score" => "score_table(my_value,0,10,1,  10,90,2 , 3 )",
        "my_value" => value
      )

      solution["my_score"]
    end
  end

  describe "support access function" do
    it "solve " do
      solution = calculator.solve("my_arr" => "access(3,6,9,1)")
      expect(solution["my_arr"]).to eq(6)
    end
  end
end