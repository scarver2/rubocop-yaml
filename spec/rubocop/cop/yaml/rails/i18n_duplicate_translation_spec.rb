# spec/rubocop/cop/yaml/rails/i18n_duplicate_translation_spec.rb
# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::YAML::Rails::I18nDuplicateTranslation do
  subject(:cop) { described_class.new }

  let(:root) { File.expand_path("../../../../fixtures/i18n_duplicates", __dir__) }
  let(:index) { RuboCop::Yaml::Rails::I18n::LocaleIndex.build(root: root) }

  it "reports every source in a three-file collision" do
    findings = cop.findings(index)
    title_findings = findings.select { |finding| finding.entry.path == "users.show.title" }

    expect(title_findings.length).to eq(3)
    expect(title_findings.map { |finding| File.basename(finding.entry.file) }).to eq(%w[one.yml three.yml two.yml])
    expect(title_findings).to all(satisfy { |finding| finding.others.length == 2 })
    expect(title_findings.first.message).to include("three.yml", "two.yml")
  end

  it "does not confuse the same path in another locale with a collision" do
    findings = cop.findings(index)

    expect(findings.map { |finding| [finding.entry.locale, finding.entry.path] }.uniq).to eq(
      [["en", "users.show.title"]]
    )
  end

  it "leaves same-file duplicate keys to YAML/Lint/DuplicateKey" do
    findings = cop.findings(index)

    expect(findings.map { |finding| finding.entry.path }).not_to include("local")
  end

  it "supports excluded files and ignored translation paths" do
    excluded = cop.findings(index, excluded_files: ["**/three.yml"])
    ignored = cop.findings(index, ignored_paths: ["users.show.*"])

    expect(excluded.count { |finding| finding.entry.path == "users.show.title" }).to eq(2)
    expect(ignored).to be_empty
  end

  it "keeps split locale trees without collisions valid" do
    findings = cop.findings(index)

    expect(findings.map { |finding| finding.entry.path }).not_to include("separate", "separate.path")
  end
end
