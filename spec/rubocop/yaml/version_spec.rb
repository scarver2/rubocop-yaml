# spec/rubocop/yaml/version_spec.rb
# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Yaml::VERSION do
  it "is a valid semantic version" do
    version = RuboCop::Yaml::VERSION

    expect(Gem::Version.new(version).to_s).to eq(version)
    expect(version).to match(/\A\d+\.\d+\.\d+(?:[.-][0-9A-Za-z]+(?:[.-][0-9A-Za-z]+)*)?(?:\+[0-9A-Za-z]+(?:[.-][0-9A-Za-z]+)*)?\z/)
  end
end
