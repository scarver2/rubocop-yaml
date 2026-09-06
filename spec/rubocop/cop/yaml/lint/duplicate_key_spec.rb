# spec/rubocop/cop/yaml/lint/duplicate_key_spec.rb
# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::YAML::Lint::DuplicateKey do
  subject(:cop) { described_class.new }

  def parse(yaml)
    RuboCop::Yaml::Parser.new.parse(yaml).stream
  end

  it "reports the later scalar key in one mapping" do
    duplicate, first = cop.duplicates(parse("name: first\nname: second\n")).first

    expect([duplicate.value, duplicate.location.line, first.location.line]).to eq(["name", 2, 1])
  end

  it "keeps separate and nested mapping scopes independent" do
    yaml = <<~YAML
      first:
        name: one
      second:
        name: two
      ---
      name: three
    YAML

    expect(cop.duplicates(parse(yaml))).to be_empty
  end

  it "detects nested duplicates" do
    duplicates = cop.duplicates(parse("outer:\n  enabled: true\n  enabled: false\n"))

    expect(duplicates.map { |key, _first| key.value }).to eq(["enabled"])
  end

  it "ignores merge keys and aliases" do
    yaml = <<~YAML
      defaults: &defaults
        enabled: true
      service:
        <<: *defaults
        <<: *defaults
    YAML

    expect(cop.duplicates(parse(yaml))).to be_empty
  end

  it "registers a native offense at the duplicate key" do
    source = "name: first\nname: second\n"
    buffer = Parser::Source::Buffer.new("duplicate.yml", source: source)
    processed_source = instance_double(
      RuboCop::ProcessedSource,
      raw_source: source,
      path: "duplicate.yml",
      buffer: buffer
    )
    allow(cop).to receive(:processed_source).and_return(processed_source)

    expect(cop).to receive(:add_offense) do |range, message:|
      expect([range.line, range.column, range.source]).to eq([2, 0, "name"])
      expect(message).to include("first declared on line 1")
    end
    cop.on_new_investigation
  end
end
