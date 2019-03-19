
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

  spec.add_dependency "activesupport"
  spec.add_dependency "colorize"
  spec.add_dependency "hesabu"
  spec.add_dependency "dentaku", "3.1.0"
  spec.add_dependency "dhis2", "2.3.8"
  spec.add_dependency "descriptive_statistics"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "ruby-prof"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "pronto"
  spec.add_development_dependency "pronto-flay"
  spec.add_development_dependency "pronto-rubocop"
  spec.add_development_dependency "pronto-simplecov"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "stackprof"
  spec.add_development_dependency "allocation_stats"
  spec.add_development_dependency "webmock"
end
