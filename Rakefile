require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

desc "Open a console with gem already loaded"
task :console do
  require "irb"
  require 'irb/completion'
  require './lib/orbf/rules_engine'
  ARGV.clear
  IRB.start
end
