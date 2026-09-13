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

        attr_reader :selected_schema

        def initialize(parser: Parser.new, registry: Registry.new)
          @parser = parser
          @registry = registry
          @schemas = {}
        end

        def validate(source:, path:, schemas:, root: Dir.pwd, autodetect: true) # rubocop:disable Metrics/AbcSize
          schema_path = schema_for(path, schemas, root, autodetect)
          return [] unless schema_path

          parsed = parser.parse(source, path: path)
          return [] unless parsed.success?

          data = to_data(parsed.stream.children.first.children.first)
          schemer(schema_path).validate(data).map { |error| finding(error, parsed.stream) }
        rescue JSON::ParserError, JSONSchemer::InvalidFileURI, JSONSchemer::UnknownRef, Psych::Exception => e
          raise ConfigurationError, "#{schema_path}: #{e.message}"
        end

        private

        attr_reader :parser, :registry, :schemas

        def schema_for(path, mappings, root, autodetect)
          relative = Pathname(path).absolute? ? Pathname(path).relative_path_from(Pathname(root)).to_s : path
          match = mappings.find { |glob, _schema| File.fnmatch?(glob, relative, File::FNM_PATHNAME | File::FNM_EXTGLOB) }
          return select_explicit(File.expand_path(match.last, root)) if match
          return unless autodetect

          select_registry(registry.resolve(relative))
        rescue ArgumentError
          nil
        end

        def select_explicit(path)
          @selected_schema = Registry::Entry.new(name: "explicit", version: "project", path: path)
          path
        end

        def select_registry(entry)
          @selected_schema = entry
          entry&.path
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

        def to_data(node)
          case node.type
          when :mapping
            node.children.each_slice(2).to_h { |key, value| [key.value, to_data(value)] }
          when :sequence
            node.children.map { |child| to_data(child) }
          when :scalar
            scalar_value(node)
          else
            node.value
          end
        end

        def scalar_value(node) # rubocop:disable Metrics/AbcSize
          return node.value unless node.plain
          return nil if %w[null ~].include?(node.value.downcase)
          return true if node.value.downcase == "true"
          return false if node.value.downcase == "false"
          return node.value.to_i if node.value.match?(/\A[-+]?\d+\z/)
          return node.value.to_f if node.value.match?(/\A[-+]?(?:\d+\.\d*|\d*\.\d+)(?:e[-+]?\d+)?\z/i)

          node.value
        end
      end
    end
  end
end
