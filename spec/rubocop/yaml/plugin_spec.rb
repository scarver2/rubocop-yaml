# spec/rubocop/yaml/plugin_spec.rb
# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Yaml::Plugin do
  subject(:plugin) { described_class.new }

  it "registers with RuboCop's plugin engine" do
    context = instance_double(LintRoller::Context, engine: :rubocop)

    expect(plugin).to be_supported(context)
    expect(plugin.about.name).to eq("rubocop-yaml")
    expect(plugin.rules(context).value).to exist
  end

  it "rejects other lint engines" do
    context = instance_double(LintRoller::Context, engine: :other)

    expect(plugin).not_to be_supported(context)
  end
end
