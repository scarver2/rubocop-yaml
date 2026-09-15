# spec/rubocop/cop/yaml/rails/i18n_interpolation_consistency_spec.rb
# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::YAML::Rails::I18nInterpolationConsistency do
  subject(:cop) { described_class.new }

  let(:root) { File.expand_path("../../../../fixtures/i18n_interpolation", __dir__) }
  let(:index) { RuboCop::Yaml::Rails::I18n::LocaleIndex.build(root: root) }

  it "reports renamed and missing placeholders at target entries" do
    findings = cop.findings(index, reference_locale: "en", locales: ["es"])

    expect(findings.map(&:path)).to eq(%w[multiline welcome])
    renamed = findings.find { |finding| finding.path == "welcome" }
    expect(renamed.message).to include("replaces `%{name}` with `%{username}`") # rubocop:disable Style/FormatStringToken
    expect(renamed.entry.file).to end_with("es.yml")
  end

  it "compares sets independently of order and repetition" do
    findings = cop.findings(index, reference_locale: "en", locales: ["es"])

    expect(findings.map(&:path)).not_to include("ordered", "repeated")
  end

  it "ignores escaped percent sequences and non-interpolated scalar leaves" do
    findings = cop.findings(index, reference_locale: "en", locales: ["es"])

    expect(findings.map(&:path)).not_to include("escaped", "numeric")
  end

  it "handles several locales, ignored paths, and a custom reference locale" do
    findings = cop.findings(
      index, reference_locale: "fr", locales: %w[en es fr], ignored_paths: ["multiline"]
    )

    expect(findings.map { |finding| [finding.locale, finding.path] }).to eq([%w[es welcome]])
  end

  it "extracts repeated and count placeholders deterministically" do
    # Rails I18n interpolation intentionally differs from Ruby's format-token style.
    value = "%{count} %{name} %{count} %%{escaped}" # rubocop:disable Style/FormatStringToken

    expect(cop.placeholders(value)).to eq(%w[count name])
  end
end
