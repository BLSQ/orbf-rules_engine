# frozen_string_literal: true

# Invoice calculation benchmark, used to spot perf regressions when upgrading
# ruby/activesupport/dentaku/hesabu.
#
#   bundle exec ruby bench/invoice_bench.rb [iterations]
#
# Runs the Liberia project (~32k equations) end to end, reports the median/min
# time of each phase, the allocations of one run and a digest of the exported
# values (must stay identical across upgrades), then appends one JSON line to
# bench/results.jsonl.

require "bundler/setup"
require "digest"
require "json"
require "time"
require "yaml"
require_relative "../lib/orbf/rules_engine"

ITERATIONS = Integer(ARGV[0] || 5)
FIXTURES = File.expand_path("../spec/fixtures/rules_engine", __dir__)

# monotonic wall time of the block (benchmark is not a default gem since ruby 4.0)
def realtime
  started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  yield
  Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
end

def load_fixture(name)
  path = File.join(FIXTURES, name)
  YAML.respond_to?(:unsafe_load_file) ? YAML.unsafe_load_file(path) : YAML.load_file(path)
end

def new_fetch_and_solve
  project = load_fixture("lib_project.yml")
  pyramid = load_fixture("lib_pyramid.yml")
  (project.packages + project.payment_rules).each { |p| p.project = project }
  $stdout = File.open(File::NULL, "w") # FetchAndSolve#initialize prints the period
  Orbf::RulesEngine::FetchAndSolve.new(project, "t3kZ5ksd8IR", "2018Q1", pyramid: pyramid, mock_values: [])
ensure
  $stdout = STDOUT
end

def run_phases(fas)
  times = {}
  args = vals = solver = exported = nil
  times[:resolve_arguments] = realtime { args = fas.send(:resolve_package_arguments) }
  times[:fetch_data] = realtime { vals = fas.send(:fetch_data, args) }
  fas.instance_variable_set(:@dhis2_values, vals)
  times[:build_equations] = realtime { solver = fas.send(:new_solver, args) }
  times[:solve] = realtime { solver.solve! }
  times[:export] = realtime do
    exported = Orbf::RulesEngine::Dhis2ValuesPrinter.new(
      solver.variables, solver.solution, **fas.send(:project).default_combos_ext_ids
    ).print
  end
  times[:total] = times.values.sum
  [times, solver, exported]
end

def median(values)
  sorted = values.sort
  mid = sorted.size / 2
  sorted.size.odd? ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2.0
end

# warm up (and correctness check)
_, solver, exported = run_phases(new_fetch_and_solve)
digest = Digest::SHA256.hexdigest(
  JSON.generate(exported.map { |v| v.transform_keys(&:to_s) }.sort_by { |v| v.values_at("dataElement", "orgUnit", "period", "categoryOptionCombo").map(&:to_s) })
)[0, 16]

GC.start
allocated_before = GC.stat(:total_allocated_objects)
run_phases(new_fetch_and_solve)
allocations = GC.stat(:total_allocated_objects) - allocated_before

runs = Array.new(ITERATIONS) do
  fas = new_fetch_and_solve
  GC.start
  run_phases(fas).first
end

phases = runs.first.keys
report = {
  at:              Time.now.utc.iso8601,
  ruby:            RUBY_VERSION,
  yjit:            defined?(RubyVM::YJIT) && RubyVM::YJIT.respond_to?(:enabled?) && RubyVM::YJIT.enabled?,
  gems:            %w[activesupport dentaku hesabu bigdecimal].map { |g| [g, Gem.loaded_specs[g]&.version&.to_s] }.to_h,
  iterations:      ITERATIONS,
  equations:       solver.solution.size,
  exported_values: exported.size,
  digest:          digest,
  allocations:     allocations,
  median_s:        phases.map { |ph| [ph, median(runs.map { |r| r[ph] }).round(4)] }.to_h,
  min_s:           phases.map { |ph| [ph, runs.map { |r| r[ph] }.min.round(4)] }.to_h
}

puts JSON.pretty_generate(report)
File.open(File.expand_path("results.jsonl", __dir__), "a") { |f| f.puts(JSON.generate(report)) }
