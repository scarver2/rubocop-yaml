# spec/rubocop/yaml/schema/validator_spec.rb
# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe RuboCop::Yaml::Schema::Validator do
  subject(:validator) { described_class.new }

  let(:schema) do
    {
      "$defs" => { "port" => { "type" => "integer" } },
      "type" => "object",
      "required" => %w[name port enabled],
      "additionalProperties" => false,
      "properties" => {
        "name" => { "type" => "string", "enum" => %w[web worker] },
        "port" => { "$ref" => "#/$defs/port" },
        "enabled" => { "type" => "boolean" },
        "labels" => { "type" => "array", "items" => { "type" => "string" } }
      }
    }
  end

  around do |example|
    Dir.mktmpdir do |directory|
      @directory = directory
      File.write(File.join(directory, "schema.json"), JSON.generate(schema))
      example.run
    end
  end

  it "accepts a valid document through a configured local schema" do
    findings = validate("name: web\nport: 3000\nenabled: true\nlabels:\n  - public\n")

    expect(findings).to be_empty
  end

  it "reports required, enum, type, nested, and additional-property violations" do
    findings = validate("name: other\nport: nope\nlabels:\n  - 10\nextra: true\n")

    expect(findings.map(&:pointer)).to include("/name", "/port", "/labels/0", "/extra")
    expect(findings.map(&:message).join(" ")).to include("required")
  end

  it "supports different schema mappings and leaves unknown files untouched" do
    mappings = { "config/*.yml" => "schema.json", "other/*.yml" => "other.json" }

    expect(validator.validate(source: "anything: goes\n", path: "unknown.yml", schemas: mappings, root: @directory)).to be_empty
  end

  it "autodetects well-known schemas but lets explicit mappings win" do
    compose = validator.validate(source: "services: {}\n", path: "compose.yml", schemas: {}, root: @directory)
    expect(compose).to be_empty
    expect(validator.selected_schema.name).to eq("Docker Compose")

    workflow = validator.validate(
      source: "on: push\njobs:\n  test: {}\n",
      path: ".github/workflows/ci.yml",
      schemas: {},
      root: @directory
    )
    expect(workflow).to be_empty
    expect(validator.selected_schema.name).to eq("GitHub Actions")

    validate("name: web\nport: 3000\nenabled: true\n")
    expect(validator.selected_schema.name).to eq("explicit")
  end

  it "can disable autodetection" do
    findings = validator.validate(
      source: "invalid: compose\n",
      path: "compose.yaml",
      schemas: {},
      root: @directory,
      autodetect: false
    )

    expect(findings).to be_empty
    expect(validator.selected_schema).to be_nil
  end

  it "caches parsed schemas within a validator run" do
    # Meta-schema validation constructs one schemer and runtime validation a
    # second; the next document reuses the cached runtime schemer.
    expect(JSONSchemer).to receive(:schema).twice.and_call_original

    2.times { validate("name: web\nport: 3000\nenabled: true\n") }
  end

  it "resolves references to sibling local schema files" do
    File.write(File.join(@directory, "port.json"), JSON.generate("type" => "integer"))
    File.write(File.join(@directory, "schema.json"), JSON.generate("$ref" => "port.json"))

    expect(validate("not-an-integer\n").first.message).to include("integer")
  end

  it "never retrieves remote references implicitly" do
    File.write(File.join(@directory, "schema.json"), JSON.generate("$ref" => "https://example.com/schema.json"))

    expect { validate("anything\n") }.to raise_error(described_class::ConfigurationError, /file.*scheme/)
  end

  it "distinguishes malformed schemas from document offenses" do
    File.write(File.join(@directory, "schema.json"), "{")

    expect { validate("name: web\n") }.to raise_error(described_class::ConfigurationError, /schema\.json/)
  end

  def validate(source)
    validator.validate(
      source: source,
      path: "config/app.yml",
      schemas: { "config/*.yml" => "schema.json" },
      root: @directory
    )
  end
end
