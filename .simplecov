# .simplecov
# frozen_string_literal: true

SimpleCov.minimum_coverage 90
SimpleCov.skip "/spec/"
# Bundler evaluates the gemspec, and therefore the version file, before RSpec can
# start coverage. The public value still has a focused behavioral spec.
SimpleCov.skip "/lib/rubocop/yaml/version.rb"
