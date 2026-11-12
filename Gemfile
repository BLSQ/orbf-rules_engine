source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in orbf-rules_engine.gemspec
gemspec

if ENV["HESABU_DEV_MODE"]
  # Run against a local copy, handy for rapid iteration
  gem "hesabu", path: "../hesabu"
else
  # Use a perhaps unreleased version for running the tests here, this
  # will not be used higher up the chain, so if an application (orbf2)
  # is using orbf-rules-engine, it will use the latest released gem
  # (unless specified otherwise)
  gem "hesabu", github: "BLSQ/hesabu" # master: ruby 4 / json 3, hesabucli go-hesabu v0.1.0
end

# legacy-v2 (2.3.8, see gemspec): the dhis2 api client orbf2 uses, ruby 3/4 fixes included
gem "dhis2", github: "BLSQ/dhis2", branch: "legacy-v2"
