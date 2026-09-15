# rubocop-yaml.gemspec
# frozen_string_literal: true

require_relative "lib/rubocop/yaml/version"

package_patterns = %w[
  CHANGELOG.md
  LICENSE
  README.md
  config/**/*.{json,yaml,yml}
  docs/**/*.md
  lib/**/*.rb
  sig/**/*.rbs
]

Gem::Specification.new do |spec|
  spec.name = "rubocop-yaml"
  spec.version = RuboCop::Yaml::VERSION
  spec.authors = ["Stan Carver II"]
  spec.email = ["howdy@stancarver.com"]
  spec.summary = "YAML analysis with native RuboCop offenses"
  spec.description = "A RuboCop plugin for deterministic YAML linting, style, schema, and Rails configuration checks."
  spec.homepage = "https://github.com/scarver2/rubocop-yaml"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"
  spec.files = Dir[*package_patterns].sort
  spec.require_paths = ["lib"]
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["default_lint_roller_plugin"] = "RuboCop::Yaml::Plugin"
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.add_dependency "i18n", ">= 1.14", "< 2.0"
  spec.add_dependency "json_schemer", ">= 2.5", "< 3.0"
  spec.add_dependency "lint_roller", "~> 1.1"
  spec.add_dependency "rubocop", ">= 1.72", "< 2.0"

  spec.add_development_dependency "rake", "~> 13.2"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "simplecov", "~> 1.2.0"
end
