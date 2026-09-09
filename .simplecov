# frozen_string_literal: true

# .simplecov
SimpleCov.minimum_coverage 90
SimpleCov.add_filter "/spec/"
# Bundler evaluates the gemspec, and therefore the version file, before RSpec can
# start coverage. The public value still has a focused behavioral spec.
SimpleCov.add_filter "/lib/rubocop/yaml/version.rb"
