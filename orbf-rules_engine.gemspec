# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "orbf/rules_engine/version"

Gem::Specification.new do |spec|
  spec.name          = "orbf-rules_engine"
  spec.version       = Orbf::RulesEngine::VERSION
  spec.authors       = ["Stéphan Mestach", "Alfred Antoine"]
  spec.email         = ["mestachs"]

  spec.summary       = "Rbf rule engine"
  spec.description   = "Rbf rule engine"
  spec.homepage      = "https://github.com/BLSQ/orbf-rules_engine"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", "5.2.6.2"
  spec.add_dependency "colorize", "0.8.1"
  spec.add_dependency "hesabu"
  spec.add_dependency "dentaku", "3.1.0"
  spec.add_dependency "dhis2", "2.3.8"
  spec.add_dependency "descriptive_statistics", "2.5.1"
  spec.add_dependency "bigdecimal", "1.3.4"

  spec.add_development_dependency "bundler", "~> 2.3.5"
  spec.add_development_dependency "ruby-prof"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "pronto"
  spec.add_development_dependency "pronto-flay"
  spec.add_development_dependency "pronto-rubocop"
  spec.add_development_dependency "pronto-simplecov"
  spec.add_development_dependency "rake", "~> 12.3"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "simplecov", "0.13.0"
  spec.add_development_dependency "stackprof", "0.2.12"
  spec.add_development_dependency "allocation_stats"
  spec.add_development_dependency "webmock", "3.4.2"
end
