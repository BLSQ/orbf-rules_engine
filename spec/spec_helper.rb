require "bundler/setup"
require "rspec"
require "simplecov"
require "byebug"

SimpleCov.start

RSpec.configure do |config|
    config.example_status_persistence_file_path = ".rspec_status"
    config.disable_monkey_patching!

    config.expect_with :rspec do |c|
      c.syntax = :expect
    end
end

require "webmock/rspec"

require_relative "./support/eq_vars"
require_relative "./support/dhis2_stubs"

require_relative "../lib/orbf/rules_engine"

def fixture_content(*path_elements)
  File.read(File.join("spec", "fixtures", path_elements.map(&:to_s)))
end
