# spec/rubocop/yaml/rails/i18n/locale_index_spec.rb
# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Yaml::Rails::I18n::LocaleIndex do
  subject(:index) { described_class.build(root: fixture_root) }

  let(:fixture_root) { File.expand_path("../../../../fixtures/i18n", __dir__) }

  it "discovers locale YAML files deterministically and records malformed files" do
    expect(index.files.map { |file| File.basename(file) }).to eq(
      %w[00_primary.yml 10_additional.yaml 20_erb.yml 30_broken.yml]
    )
    expect(index.diagnostics.map { |diagnostic| File.basename(diagnostic.path) }).to eq(["30_broken.yml"])
    expect(index.diagnostics.first.line).to be_positive
    expect(index.diagnostics.first.column).to be_positive
  end

  it "indexes locales and stable dotted translation paths across files and documents" do
    expect(index.locales).to eq(%w[en es fr de])
    expect(index.translations_for(:en).keys).to include("users", "users.welcome", "admin.title")
    expect(index.entries_for(:de, :greeting).first.document).to eq(1)
    expect(index.translations_for(:fr)).to be_empty
  end

  it "preserves every colliding entry with exact source information" do
    entries = index.entries_for("en", "users.welcome")

    # Rails I18n interpolation intentionally differs from Ruby's format-token style.
    expect(entries.map(&:value)).to eq(["Hello %{name}", "Welcome again"]) # rubocop:disable Style/FormatStringToken
    expect(entries.map { |entry| File.basename(entry.file) }).to eq(%w[00_primary.yml 10_additional.yaml])
    expect(entries.map(&:line)).to all(be_positive)
    expect(entries.map(&:column)).to all(be_positive)
    expect(entries.map(&:node)).to all(be_a(RuboCop::Yaml::Parser::Node))
  end

  it "retains scalar, sequence, and mapping node types without evaluating values" do
    expect(index.entries_for("en", "users").first.type).to eq(:mapping)
    expect(index.entries_for("en", "users.roles").first.type).to eq(:sequence)
    expect(index.entries_for("en", "users.welcome").first.type).to eq(:scalar)
    expect(index.entries_for("en", "literal").first.value).to eq("<%= Kernel.raise('must not execute') %>")
  end

  it "indexes mappings reached through YAML aliases without deserializing objects" do
    copied_title = index.entries_for("en", "copied.title").first

    expect(copied_title.value).to eq("Shared title")
    expect(copied_title.node.type).to eq(:scalar)
  end

  it "supports configured discovery patterns" do
    configured = described_class.build(root: fixture_root, patterns: ["config/locales/20_erb.yml"])

    expect(configured.files.map { |file| File.basename(file) }).to eq(["20_erb.yml"])
    expect(configured.entries_for("en", "literal")).not_to be_empty
    expect(configured.diagnostics).to be_empty
  end

  it "exposes a deterministic enumerator and immutable results" do
    expect(index.each_entry.map(&:path)).to include("users.welcome", "admin.title", "greeting")
    expect(index.files).to be_frozen
    expect(index.diagnostics).to be_frozen
    expect(index.translations_for("en")).to be_frozen
    expect(index.entries_for("en", "users.welcome")).to be_frozen
  end
end
