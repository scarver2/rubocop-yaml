# lib/rubocop/cop/yaml/base.rb
# frozen_string_literal: true

require "rubocop"
require_relative "../../yaml/processed_source"

module RuboCop
  module Cop
    module YAML
      class Base < RuboCop::Cop::Base
        def relevant_file?(file)
          file.to_s.match?(RuboCop::Yaml::ProcessedSource::YAML_EXTENSION) && super
        end

        private

        def yaml_result
          @yaml_result ||= RuboCop::Yaml::Parser.new.parse(
            processed_source.raw_source,
            path: processed_source.path
          )
        end

        def source_range(line, column, length = 1)
          buffer = processed_source.buffer
          begin_pos = buffer.line_range(line).begin_pos + column - 1
          Parser::Source::Range.new(buffer, begin_pos, begin_pos + length)
        end
      end
    end
  end
end
