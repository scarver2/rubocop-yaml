# lib/rubocop/yaml/processed_source.rb
# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Yaml
    module ProcessedSource
      YAML_EXTENSION = /\.ya?ml\z/i

      def from_file(path, ruby_version, parser_engine: :default)
        return super unless path.to_s.match?(YAML_EXTENSION)

        yaml = File.binread(path)
        source = new("", ruby_version, path, parser_engine: parser_engine)
        buffer = ::Parser::Source::Buffer.new(path.to_s, source: yaml)
        source.instance_variable_set(:@raw_source, yaml)
        source.instance_variable_set(:@buffer, buffer)
        source
      end
    end
  end
end

RuboCop::ProcessedSource.singleton_class.prepend(RuboCop::Yaml::ProcessedSource)
