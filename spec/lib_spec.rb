require "ruby-prof"
require "allocation_stats"

RSpec.describe "Liberia System" do
  let(:period) { "2016Q1" }

  let(:project) { YAML.load_file(File.new("./spec/fixtures/rules_engine/lib_project.yml")) }
  let(:pyramid) { YAML.load_file(File.new("./spec/fixtures/rules_engine/lib_pyramid.yml")) }

  let(:fetch_and_solve) do
    Orbf::RulesEngine::FetchAndSolve.new(
      project,
      "t3kZ5ksd8IR",
      "2018Q1",
      pyramid:     pyramid,
      mock_values: []
    )
  end
  it "works" do
    # fetch_and_solve.call
    project
    pyramid

    RubyProf.start if ENV["PROF"]
    require "objspace"


    stats = AllocationStats.new if ENV["ALLOC"]
    stats.trace if ENV["ALLOC"]

    fetch_and_solve.call
    Orbf::RulesEngine::InvoicePrinter.new(fetch_and_solve.solver.variables, fetch_and_solve.solver.solution).print

    stats.stop if ENV["ALLOC"]
    if ENV["ALLOC"]
      puts stats.allocations(alias_paths: true).group_by(:sourcefile, :sourceline, :class).at_least(100).sort_by_count.to_text
    end
    result = RubyProf.stop if ENV["PROF"]

    if ENV["PROF"]
      printer = RubyProf::GraphPrinter.new(result)
      printer.print(STDOUT, {})

      printer = RubyProf::FlatPrinter.new(result)
      printer.print(STDOUT, {})
    end

    expect(fetch_and_solve.solver.solution.size).to eq(32_109)

    fixture_record(fetch_and_solve.exported_values, :rules_engine, "lib_exported_values.json")

    # Only here to help with comparing
    index_by_unique = ->(json) {
      arr = JSON.parse(json)
      arr.index_by do |h|
        [h["period"], h["orgUnit"], h["dataElement"]]
      end
    }
    expected = index_by_unique.call(fixture_content(:rules_engine, "lib_exported_values.json"))
    new_values = index_by_unique.call(fetch_and_solve.exported_values.to_json)

    expect(new_values).to eq(expected)
    expect(fetch_and_solve.exported_values.size).to eq(4202)
  end
end
