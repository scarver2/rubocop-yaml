# spec/rubocop/cop/yaml/style/key_ordering_spec.rb
# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::YAML::Style::KeyOrdering do
  subject(:cop) { described_class.new }

  def parse(yaml)
    RuboCop::Yaml::Parser.new.parse(yaml).stream
  end

  it "detects alphabetical ordering violations at every mapping depth" do
    yaml = "zebra: one\nalpha: two\nnested:\n  zulu: three\n  beta: four\n"
    violations = cop.violations(parse(yaml), style: :alphabetical)

    expect(violations.map { |key, previous| [key.value, previous.value] }).to eq(
      [%w[alpha zebra], %w[beta zulu]]
    )
  end

  it "enforces configured key sequences while leaving unknown keys in place" do
    yaml = "custom: value\ndescription: Example\nname: app\nversion: 1\n"
    violations = cop.violations(parse(yaml), style: :configured, keys: %w[name description version])

    expect(violations.map { |key, previous| [key.value, previous.value] }).to eq([%w[name description]])
  end

  it "ignores mappings with merge or non-scalar keys" do
    yaml = "defaults: &defaults {}\nservice:\n  zed: true\n  <<: *defaults\n  alpha: true\n"

    expect(cop.violations(parse(yaml), style: :alphabetical)).to be_empty
  end

  it "does not offer autocorrection because comments and aliases must be preserved" do
    expect(described_class.support_autocorrect?).to be(false)
  end
end
