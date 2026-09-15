# spec/rubocop/cop/yaml/rails/i18n_pluralization_contract_spec.rb
# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::YAML::Rails::I18nPluralizationContract do
  subject(:cop) { described_class.new }

  let(:root) { File.expand_path("../../../../fixtures/i18n_pluralization", __dir__) }
  let(:index) { RuboCop::Yaml::Rails::I18n::LocaleIndex.build(root: root) }

  it "applies an evidence-backed English one/other contract" do
    findings = cop.findings(index, required_categories: { "en" => %w[one other] })

    expect(findings.map(&:path)).to eq(["alerts"])
    expect(findings.first.message).to include("missing categories: other")
  end

  it "does not apply English categories to unconfigured locales" do
    findings = cop.findings(index, required_categories: { "en" => %w[one other] })

    expect(findings.map(&:locale)).not_to include("ja", "ru")
  end

  it "supports explicit locale-specific and custom category policies" do
    findings = cop.findings(
      index,
      required_categories: { "ja" => ["other"], "ru" => %w[one few many other] }
    )

    expect(findings.map { |finding| [finding.locale, finding.path] }).to eq([%w[ru inbox]])
    expect(findings.first.message).to include("other")
  end

  it "never mistakes scalar or non-plural mappings for pluralization maps" do
    findings = cop.findings(index, required_categories: { "en" => %w[one other] })

    expect(findings.map(&:path)).not_to include("scalar", "settings")
  end

  it "optionally verifies count interpolation for configured categories" do
    findings = cop.findings(
      index,
      required_categories: { "en" => %w[one other] },
      count_required_categories: { "en" => %w[one other] }
    )

    # The assertion intentionally contains the literal Ruby I18n placeholder syntax.
    expected = "Locale `en` pluralization `inbox.one` must interpolate `%{count}`." # rubocop:disable Style/FormatStringToken
    expect(findings.map(&:message)).to include(expected)
  end

  it "supports ignored pluralization paths" do
    findings = cop.findings(
      index, required_categories: { "en" => %w[one other] }, ignored_paths: ["alerts"]
    )

    expect(findings).to be_empty
  end
end
