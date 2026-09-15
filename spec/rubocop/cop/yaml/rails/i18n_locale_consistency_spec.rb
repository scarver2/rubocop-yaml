# spec/rubocop/cop/yaml/rails/i18n_locale_consistency_spec.rb
# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::YAML::Rails::I18nLocaleConsistency do
  subject(:cop) { described_class.new }

  let(:root) { File.expand_path("../../../../fixtures/i18n_consistency", __dir__) }
  let(:index) { RuboCop::Yaml::Rails::I18n::LocaleIndex.build(root: root) }

  it "finds missing paths across split files and three locales" do
    findings = cop.findings(index, reference_locale: "en")

    expect(findings.map { |finding| [finding.locale, finding.path] }).to eq(
      [["es", "regional"], ["es", "users.profile"], ["fr", "sessions"], ["fr", "users.welcome"]]
    )
  end

  it "collapses an entirely missing subtree into one deterministic finding" do
    findings = cop.findings(index, reference_locale: "en", locales: ["es"])

    expect(findings.map(&:path)).to include("users.profile")
    expect(findings.map(&:path)).not_to include("users.profile.title", "users.profile.subtitle")
    expect(findings.map(&:entry)).to all(be_a(RuboCop::Yaml::Rails::I18n::LocaleIndex::Entry))
  end

  it "supports ignored locales and translation path patterns" do
    findings = cop.findings(
      index, reference_locale: "en", ignored_locales: ["fr"], ignored_paths: ["regional*"]
    )

    expect(findings.map { |finding| [finding.locale, finding.path] }).to eq([["es", "users.profile"]])
  end

  it "supports a custom reference locale without comparing it to itself" do
    findings = cop.findings(index, reference_locale: "fr", locales: %w[en fr])

    expect(findings.map { |finding| [finding.locale, finding.path] }).to eq([])
  end

  it "describes the missing path, target locale, and reference locale" do
    finding = cop.findings(index, reference_locale: "en", locales: ["es"]).first

    expect(finding.message).to include("Locale `es`", "reference locale `en`")
  end
end
