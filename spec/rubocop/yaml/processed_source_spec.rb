# spec/rubocop/yaml/processed_source_spec.rb
# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe RuboCop::Yaml::ProcessedSource do
  it "preserves YAML source without asking RuboCop's Ruby parser to parse it" do
    Tempfile.create(["example", ".yml"]) do |file|
      file.write("name: value\n")
      file.flush

      source = RuboCop::ProcessedSource.from_file(file.path, 3.2)

      expect(source.raw_source).to eq("name: value\n")
      expect(source.buffer.source).to eq("name: value\n")
      expect(source.diagnostics).to be_empty
    end
  end

  it "delegates Ruby files to RuboCop unchanged" do
    Tempfile.create(["example", ".rb"]) do |file|
      file.write("value = 1\n")
      file.flush

      source = RuboCop::ProcessedSource.from_file(file.path, 3.2)

      expect(source.ast).not_to be_nil
      expect(source.raw_source).to eq("value = 1\n")
    end
  end
end
