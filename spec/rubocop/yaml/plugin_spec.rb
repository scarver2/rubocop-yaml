# spec/rubocop/yaml/plugin_spec.rb
# frozen_string_literal: true

require "spec_helper"
require "json"
require "open3"
require "tmpdir"

RSpec.describe RuboCop::Yaml::Plugin do
  subject(:plugin) { described_class.new }

  it "registers with RuboCop's plugin engine" do
    context = instance_double(LintRoller::Context, engine: :rubocop)

    expect(plugin).to be_supported(context)
    expect(plugin.about.name).to eq("rubocop-yaml")
    expect(plugin.rules(context).value).to exist
  end

  it "rejects other lint engines" do
    context = instance_double(LintRoller::Context, engine: :other)

    expect(plugin).not_to be_supported(context)
  end

  it "reports YAML offenses without treating Ruby as YAML in a mixed project" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, ".rubocop.yml"), "plugins: [rubocop-yaml]\nAllCops:\n  NewCops: disable\n")
      File.write(File.join(dir, "example.rb"), "def example\n  { key: 1 }\nend\n")
      File.write(File.join(dir, "broken.yaml"), "key: [unterminated\n")
      File.write(File.join(dir, "duplicate.yml"), "key: one\nkey: two\n")

      stdout, stderr, status = Open3.capture3(
        Gem.ruby, Gem.bin_path("rubocop", "rubocop"), "--cache", "false", "--format", "json",
        "--only", "YAML/Lint/InvalidSyntax,YAML/Lint/DuplicateKey", chdir: dir
      )

      expect(status.exitstatus).to eq(1), stderr
      offenses = JSON.parse(stdout).fetch("files").to_h do |file|
        [file.fetch("path"), file.fetch("offenses").map { |offense| offense.fetch("cop_name") }]
      end
      expect(offenses).to eq(
        "example.rb" => [],
        "broken.yaml" => ["YAML/Lint/InvalidSyntax"],
        "duplicate.yml" => ["YAML/Lint/DuplicateKey"]
      )
    end
  end
end
