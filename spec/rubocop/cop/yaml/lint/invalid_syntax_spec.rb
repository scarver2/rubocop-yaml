# spec/rubocop/cop/yaml/lint/invalid_syntax_spec.rb
# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::YAML::Lint::InvalidSyntax do
  subject(:cop) { described_class.new }

  it "does not report valid YAML" do
    processed_source = instance_double(
      RuboCop::ProcessedSource,
      raw_source: "key: value\nitems:\n  - one\n",
      path: "valid.yml"
    )
    allow(cop).to receive(:processed_source).and_return(processed_source)

    expect(cop).not_to receive(:add_offense)
    cop.on_new_investigation
  end

  it "reports malformed YAML at the parser location" do
    buffer = Parser::Source::Buffer.new("broken.yml", source: "key: [unterminated\n")
    processed_source = instance_double(
      RuboCop::ProcessedSource,
      raw_source: buffer.source,
      path: "broken.yml",
      buffer: buffer
    )
    allow(cop).to receive(:processed_source).and_return(processed_source)

    expect(cop).to receive(:add_offense) do |range, message:|
      expect(range.line).to eq(1)
      expect(message).to start_with("Invalid YAML syntax:")
    end
    cop.on_new_investigation
  end

  [
    "key: value\n  child: value\n",
    "items:\n\t- one\n",
    "quote: 'unterminated\n",
    "---\nvalid: yes\n---\nbroken: [\n"
  ].each do |yaml|
    it "returns a structured parser failure for #{yaml.inspect}" do
      expect(RuboCop::Yaml::Parser.new.parse(yaml).diagnostic).not_to be_nil
    end
  end
end
