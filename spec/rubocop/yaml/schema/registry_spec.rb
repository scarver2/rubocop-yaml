# spec/rubocop/yaml/schema/registry_spec.rb
# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Yaml::Schema::Registry do
  subject(:registry) { described_class.new }

  it "resolves Compose filename variants deterministically" do
    %w[compose.yml compose.yaml docker-compose.yml].each do |path|
      entry = registry.resolve(path)
      expect([entry.name, entry.version]).to eq(["Docker Compose", "compose-spec-2026-08"])
      expect(entry.path).to end_with("config/schemas/compose.json")
    end
  end

  it "resolves workflow files only inside .github/workflows" do
    entry = registry.resolve(".github/workflows/ci.yml")

    expect(entry.name).to eq("GitHub Actions")
    expect(registry.resolve("ci.yml")).to be_nil
  end
end
