# spec/rubocop/cop/yaml/rails/i18n_orphan_translation_spec.rb
# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::YAML::Rails::I18nOrphanTranslation do
  subject(:cop) { described_class.new }

  let(:root) { File.expand_path("../../../../fixtures/i18n_orphans", __dir__) }
  let(:index) { RuboCop::Yaml::Rails::I18n::LocaleIndex.build(root: root) }

  it "reports target-only leaf paths across split files and locales" do
    findings = cop.findings(index, reference_locale: "en")

    expect(findings.map { |finding| [finding.locale, finding.path] }).to eq(
      [%w[es regional.greeting], %w[es typo.greting], %w[es users.stale], %w[fr legal.notice]]
    )
    expect(findings.map { |finding| File.basename(finding.entry.file) }).to include("es_extra.yml")
  end

  it "does not report paths present in the reference locale" do
    findings = cop.findings(index, reference_locale: "en")

    expect(findings.map(&:path)).not_to include("users.title")
  end

  it "supports global and locale-specific approved namespaces" do
    findings = cop.findings(
      index,
      reference_locale: "en",
      ignored_paths: ["regional.*"],
      locale_ignored_paths: { "fr" => ["legal.*"], "es" => ["typo.*"] }
    )

    expect(findings.map { |finding| [finding.locale, finding.path] }).to eq([%w[es users.stale]])
  end

  it "supports locale allowlists and ignore lists" do
    allowlisted = cop.findings(index, reference_locale: "en", locales: ["fr"])
    ignored = cop.findings(index, reference_locale: "en", ignored_locales: ["fr"])

    expect(allowlisted.map(&:locale).uniq).to eq(["fr"])
    expect(ignored.map(&:locale)).not_to include("fr")
  end

  it "anchors each finding directly to the extra translation" do
    finding = cop.findings(index, reference_locale: "en").find { |item| item.path == "typo.greting" }

    expect(finding.entry.line).to be_positive
    expect(finding.entry.column).to be_positive
    expect(finding.message).to include("reference locale `en`")
  end
end
