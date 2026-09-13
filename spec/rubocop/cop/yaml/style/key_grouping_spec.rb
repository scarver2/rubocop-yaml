# spec/rubocop/cop/yaml/style/key_grouping_spec.rb
# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::YAML::Style::KeyGrouping do
  subject(:cop) { described_class.new }

  let(:groups) do
    [
      { "Name" => "metadata", "Keys" => %w[name description] },
      { "Name" => "runtime", "Keys" => %w[command environment] }
    ]
  end

  def parse(yaml)
    RuboCop::Yaml::Parser.new.parse(yaml).stream
  end

  it "detects configured groups out of order without requiring missing groups" do
    options = { "Groups" => groups, "Scopes" => ["*"] }

    expect(cop.findings(parse("command: run\nname: app\n"), options).map(&:message)).to contain_exactly(
      "Place `name` with the earlier `metadata` key group."
    )
    expect(cop.findings(parse("command: run\n"), options)).to be_empty
  end

  it "supports configured nested mapping scopes" do
    yaml = "services:\n  web:\n    command: run\n    name: app\nother:\n  command: run\n  name: ignored\n"
    options = { "Groups" => groups, "Scopes" => ["services.web"] }

    expect(cop.findings(parse(yaml), options).map { |finding| finding.key.location.line }).to eq([4])
  end

  it "can place unknown keys last or ignore their placement" do
    yaml = "custom: value\nname: app\n"

    last = cop.findings(parse(yaml), "Groups" => groups, "Scopes" => ["*"], "UnknownKeys" => "last")
    ignored = cop.findings(parse(yaml), "Groups" => groups, "Scopes" => ["*"], "UnknownKeys" => "ignore")

    expect(last.length).to eq(1)
    expect(ignored).to be_empty
  end

  it "optionally requires blank lines between present groups" do
    options = { "Groups" => groups, "Scopes" => ["*"], "RequireBlankLines" => true }
    compact = parse("name: app\ncommand: run\n")
    separated = parse("name: app\n\ncommand: run\n")

    expect(cop.findings(compact, options).map(&:message)).to include("Separate the `runtime` key group with a blank line.")
    expect(cop.findings(separated, options)).to be_empty
  end

  it "does not offer autocorrection around comments and YAML semantics" do
    expect(described_class.support_autocorrect?).to be(false)
  end
end
