# lib/rubocop/yaml/schema/validator.rb
# frozen_string_literal: true

require "json_schemer"
require "pathname"
require "psych"

module RuboCop
  module Yaml
    module Schema
      class Validator
        Finding = Struct.new(:pointer, :message, :line, :column, keyword_init: true)

        class ConfigurationError < StandardError; end

        def initialize(parser: Parser.new)
          @parser = parser
          @schemas = {}
        end

        def validate(source:, path:, schemas:, root: Dir.pwd)
          schema_path = schema_for(path, schemas, root)
          return [] unless schema_path

          parsed = parser.parse(source, path: path)
          return [] unless parsed.success?

          data = Psych.safe_load(source, aliases: true)
          schemer(schema_path).validate(data).map { |error| finding(error, parsed.stream) }
        rescue JSON::ParserError, JSONSchemer::InvalidFileURI, JSONSchemer::UnknownRef, Psych::Exception => e
          raise ConfigurationError, "#{schema_path}: #{e.message}"
        end

        private

        attr_reader :parser, :schemas

        def schema_for(path, mappings, root)
          relative = Pathname(path).absolute? ? Pathname(path).relative_path_from(Pathname(root)).to_s : path
          match = mappings.find { |glob, _schema| File.fnmatch?(glob, relative, File::FNM_PATHNAME | File::FNM_EXTGLOB) }
          File.expand_path(match.last, root) if match
        rescue ArgumentError
          nil
        end

        def schemer(path)
          schemas[path] ||= begin
            pathname = Pathname(path)
            raise ConfigurationError, "schema does not exist" unless pathname.file?
            raise ConfigurationError, "schema is malformed" unless JSONSchemer.valid_schema?(pathname)

            JSONSchemer.schema(pathname)
          end
        end

        def finding(error, stream)
          node = node_at(stream, error.fetch("data_pointer"))
          Finding.new(
            pointer: error.fetch("data_pointer"),
            message: error.fetch("error"),
            line: node.location.line,
            column: node.location.column
          )
        end

        def node_at(stream, pointer)
          node = stream.children.first.children.first
          decode_pointer(pointer).each do |part|
            next_node = child_at(node, part)
            break unless next_node

            node = next_node
          end
          node
        end

        def child_at(node, part)
          return node.children[part.to_i] if node.type == :sequence
          return unless node.type == :mapping

          pair = node.children.each_slice(2).find { |key, _value| key.value == part }
          pair&.last || pair&.first
        end

        def decode_pointer(pointer)
          pointer.split("/").drop(1).map { |part| part.gsub("~1", "/").gsub("~0", "~") }
        end
      end
    end
  end
end
