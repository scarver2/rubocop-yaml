# spec/rubocop/yaml/parser_spec.rb
# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Yaml::Parser do
  subject(:parser) { described_class.new }

  it "parses streams with source locations" do
    result = parser.parse("first: one\n---\nsecond: two\n", path: "example.yml")

    expect(result).to be_success
    expect(result.stream.type).to eq(:stream)
    expect(result.stream.children.map(&:type)).to eq(%i[document document])
    scalar = result.stream.children.first.children.first.children.first
    expect([scalar.value, scalar.location.line, scalar.location.column]).to eq(["first", 1, 1])
  end

  it "represents anchors, aliases, and tags without deserializing objects" do
    result = parser.parse("base: &base !thing\n  enabled: true\ncopy: *base\n")
    nodes = walk(result.stream)

    expect(nodes.map(&:type)).to include(:alias)
    expect(nodes.map(&:anchor)).to include("base")
    expect(nodes.map(&:tag)).to include("!thing")
  end

  it "returns structured diagnostics for malformed YAML" do
    result = parser.parse("items:\n  - ok\n bad: nope\n", path: "broken.yml")

    expect(result).not_to be_success
    expect(result.diagnostic.path).to eq("broken.yml")
    expect(result.diagnostic.line).to be_positive
    expect(result.diagnostic.column).to be_positive
    expect(result.diagnostic.message).not_to be_empty
  end

  def walk(node)
    [node, *node.children.flat_map { |child| walk(child) }]
  end
end
