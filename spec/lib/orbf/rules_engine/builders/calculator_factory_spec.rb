RSpec.describe Orbf::RulesEngine::CalculatorFactory do
  [2, 3].each do |version|
    describe "engine version #{version}" do
      let(:calculator) { described_class.build(version) }

      describe "support sum function" do
        it "solve " do
          solution = calculator.solve("myavg" => "sum(1,3,9)")
          expect(solution["myavg"].to_f).to eq(13)
        end
      end

      describe "support avg function" do
        it "solve " do
          solution = calculator.solve("myavg" => "AVG(1,3,9)")
          expect(solution["myavg"].to_f).to eq(4.333333333333333)
        end
      end

      describe "support stdevp function" do
        it "solve " do
          solution = calculator.solve("mystdevp" => "STDEVP(1,3,9)")
          expect(solution["mystdevp"].to_f).to eq(3.39934634239519)
        end
      end

      describe "support stdevp function" do
        it "solve " do
          solution = calculator.solve("mystdevp" => "round(12 + STDEVP(1,3,9) + sqrt(4) , 2)")
          expect(solution["mystdevp"].to_f).to eq(17.4)
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
        it "solve" do
          solution = calculator.solve("my_arr" => "access(3,6,9,1)")
          expect(solution["my_arr"]).to eq(6)
        end
      end

      describe "support floor function" do
        [
          [33.3333333, nil, 33.0],
          [-33.3333333, nil, -34.0],
          [33.3333333, 10.0, 30.0],
          [-33.3333333, 10.0, -40.0]
        ].each do |example|
          it "solve #{example}" do
            equation = if example[1].nil?
                         "floor(#{example[0]})"
                       else
                         "floor(#{example[0]}, #{example[1]})"
                       end
            solution = calculator.solve("my_arr" => equation)
            expect(solution["my_arr"]).to eq(example[2])
          end
        end
      end

      describe "support save_div function" do
        it "solve" do
          solution = calculator.solve("my_arr" => "safe_div(3,6)")
          expect(solution["my_arr"]).to eq(0.5)
        end
        it "doesn't divide by 0" do
          solution = calculator.solve("my_arr" => "safe_div(3,0)")
          expect(solution["my_arr"]).to eq(0)
        end
      end

      describe "support abs function" do
        it "solve" do
          solution = calculator.solve("my_var" => "abs(-1.5)")
          expect(solution["my_var"]).to eq(1.5)
        end
      end

      describe "support sqrt function" do
        it "solve" do
          solution = calculator.solve("my_var" => "sqrt(4.0)")
          expect(solution["my_var"]).to eq(2.0)
        end
      end

      describe "support randbetween function" do
        it "solve" do
          solution = calculator.solve("my_var" => "randbetween(1, 4)")
          expect(solution["my_var"]).to be_between(1, 4)
        end
      end

      describe "support cal_days_in_month function" do
        it "solve" do
          solution = calculator.solve("my_var" => "cal_days_in_month(2020,1)")
          expect(solution["my_var"]).to eq(31)
        end
        it "solve knowing about leap year" do
          solution = calculator.solve("my_var" => "cal_days_in_month(2020,2)")
          expect(solution["my_var"]).to eq(29)
        end
      end

      describe "eval_array" do
        it "solves" do
          solution = calculator.solve("my_var" => "sum(eval_array('a', ARRAY(1.5,-3,4), 'b', ARRAY(2,-4,5.2), 'b - a'))")
          expected_result = ((2 - 1.5) + (-4 - -3) + (5.2 - 4))
          expect(solution["my_var"]).to be_within(0.000001).of(expected_result)
        end

        describe "raises on invalid input" do
          it "not same length arrays" do
            expected_error_class = Hesabu::Error
            expected_error_match = "In equation my_var Error for evalArray-function, Expected 'a' and 'b' to have same size of values (0 and 1) my_var := sum(eval_array('a', ARRAY(), 'b', ARRAY(1), 'b - a'))"
            if version < 3
              expected_error_class = Dentaku::ArgumentError
              expected_error_match = "EVAL_ARRAY() requires 'a' and 'b' in (b - a) to have same size of values"
            end
            expect do
              calculator.solve!("my_var" => "sum(eval_array('a', ARRAY(), 'b', ARRAY(1), 'b - a'))")
            end.to raise_error(expected_error_class, expected_error_match)
          end

          it "missing keys for meta formula" do
            expected_error_class = Hesabu::Error
            expected_error_match = "In equation my_var Error for EVAL_ARRAY()-function, No parameter 'some' found.. We only know 'a' and 'b' my_var := eval_array('a', ARRAY(1,2), 'b', ARRAY(1,2), 'some - var')"
            if version < 3
              expected_error_class = Dentaku::ArgumentError
              expected_error_match = "EVAL_ARRAY() some - var uses: 'some', 'var'. We only know: 'a', 'b'"
            end
            expect do
              calculator.solve!("my_var" => "eval_array('a', ARRAY(1,2), 'b', ARRAY(1,2), 'some - var')")
            end.to raise_error(expected_error_class, expected_error_match)
          end
        end
      end

      describe "array" do
        it "allows ARRAY" do
          solution = calculator.solve("my_var" => "sum(ARRAY(5,15,10))")
          expect(solution["my_var"]).to eq(5 + 15 + 10)
        end

        it "allows array" do
          solution = calculator.solve("my_var" => "sum(array(5,15,10))")
          expect(solution["my_var"]).to eq(5 + 15 + 10)
        end
      end

      describe "array as variable" do
        {
          "sum"    => ["sum(arr)", 9.0],
          "max"    => ["max(arr)", 5.0],
          "min"    => ["min(arr)", -3],
          "avg"    => ["avg(arr)", 1.8],
          "access" => ["access(arr,1)", 2.0]
        }.each do |function_name, (formula, expected)|
          it "supports #{function_name}" do
            solution = calculator.solve("arr" => "array(1,2,-3,4,5)", "my_var" => formula)
            expect(solution["my_var"]).to eq(expected)
          end
        end

        it "supports nesting the arrays" do
          solution = calculator.solve(
            "arr"        => "array(1,2,-3,4,5)",
            "evaled_arr" => "eval_array('a', arr, 'b', arr, 'a - b')",
            "result"     => "sum(evaled_arr)"
          )
          expect(solution["result"]).to eq(0.0)
        end

        it "'exports' the array" do
          solution = calculator.solve(
            "arr" => "array(1,2,-3,4,5)"
          )
          expect(solution["arr"]).to eq([1, 2, -3, 4, 5])
        end
      end
    end
  end
end
