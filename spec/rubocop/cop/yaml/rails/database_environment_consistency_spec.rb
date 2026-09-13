# spec/rubocop/cop/yaml/rails/database_environment_consistency_spec.rb
# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::YAML::Rails::DatabaseEnvironmentConsistency do
  subject(:cop) { described_class.new }

  let(:parser) { RuboCop::Yaml::Parser.new }
  let(:required_environments) { %w[development test production] }
  let(:required_keys) { %w[adapter database] }

  it "accepts realistic Rails configuration using anchors and merge keys" do
    findings = inspect_fixture("database_valid.yml")

    expect(findings).to be_empty
  end

  it "reports missing required keys and environments" do
    findings = inspect_fixture("database_invalid.yml")

    expect(findings.map(&:message)).to contain_exactly(
      "Database environment `test` is missing required key `database`.",
      "Define the `production` database environment."
    )
    expect(findings.map { |finding| finding.node.location.line }).to all(be_positive)
  end

  it "supports nonstandard environment and key policies" do
    stream = parser.parse("review:\n  url: sqlite3:tmp/review.sqlite3\n").stream
    findings = cop.findings(
      stream,
      required_environments: ["review"],
      required_keys: ["url"],
      allow_merge_keys: false
    )

    expect(findings).to be_empty
  end

  it "reports every required key when an environment is not a mapping" do
    stream = parser.parse("development: invalid\n").stream
    findings = cop.findings(
      stream,
      required_environments: ["development"],
      required_keys: required_keys
    )

    expect(findings.map(&:message)).to match_array([
                                                     "Database environment `development` is missing required key `adapter`.",
                                                     "Database environment `development` is missing required key `database`."
                                                   ])
  end

  def inspect_fixture(name)
    path = File.expand_path("../../../../fixtures/rails/#{name}", __dir__)
    stream = parser.parse(File.read(path), path: path).stream
    cop.findings(stream, required_environments: required_environments, required_keys: required_keys)
  end
end
