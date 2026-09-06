# spec/spec_helper.rb
# frozen_string_literal: true

require "simplecov"
SimpleCov.start "rails"

require "rubocop/yaml"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |expectations| expectations.syntax = :expect }
end
