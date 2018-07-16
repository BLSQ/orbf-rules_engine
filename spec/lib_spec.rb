require 'ruby-prof'

RSpec.describe "Liberia System" do
    let(:period) { "2016Q1" }

    let(:project) { YAML::load_file(File.new("./spec/fixtures/rules_engine/lib_project.yml")) }
    let(:pyramid) { YAML::load_file(File.new("./spec/fixtures/rules_engine/lib_pyramid.yml")) }

    let(:fetch_and_solve) { Orbf::RulesEngine::FetchAndSolve.new(
        project, 
        "t3kZ5ksd8IR", 
        "2018Q1", 
        pyramid: pyramid, 
        mock_values: [])}
    it "works" do

        #fetch_and_solve.call
        project
        pyramid
        
        RubyProf.start if ENV["PROF"]
        fetch_and_solve.call
        result = RubyProf.stop if ENV["PROF"]

        if ENV["PROF"]
            printer = RubyProf::GraphPrinter.new(result)
            printer.print(STDOUT, {})

            printer = RubyProf::FlatPrinter.new(result)
            printer.print(STDOUT, {})
        end

        expect(fetch_and_solve.solver.solution.size).to eq(32149)
        expect(fetch_and_solve.exported_values.size).to eq(4202)
        
    end
end