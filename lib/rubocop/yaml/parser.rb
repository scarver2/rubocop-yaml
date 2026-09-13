# lib/rubocop/yaml/parser.rb
# frozen_string_literal: true

require "psych"

module RuboCop
  module Yaml
    class Parser
      Location = Struct.new(:line, :column, :end_line, :end_column, keyword_init: true)
      Diagnostic = Struct.new(:path, :line, :column, :message, keyword_init: true)
      Result = Struct.new(:stream, :diagnostic, keyword_init: true) do
        def success?
          diagnostic.nil?
        end
      end

      class Node
        attr_reader :type, :value, :children, :location, :anchor, :tag

        def initialize(type:, value:, children:, location:, anchor:, tag:) # rubocop:disable Metrics/ParameterLists
          @type = type
          @value = value
          @children = children.freeze
          @location = location
          @anchor = anchor
          @tag = tag
          freeze
        end
      end

      def parse(source, path: "(yaml)")
        Result.new(stream: convert(Psych.parse_stream(source, filename: path)))
      rescue Psych::SyntaxError => e
        Result.new(
          diagnostic: Diagnostic.new(path: path, line: e.line, column: e.column, message: e.problem)
        )
      end

      private

      def convert(node) # rubocop:disable Metrics/AbcSize
        Node.new(
          type: node.class.name.split("::").last.downcase.to_sym,
          value: node.respond_to?(:value) ? node.value : nil,
          children: Array(node.children).map { |child| convert(child) },
          location: location(node),
          anchor: node.respond_to?(:anchor) ? node.anchor : nil,
          tag: node.respond_to?(:tag) ? node.tag : nil
        )
      end

      def location(node)
        Location.new(
          line: node.start_line + 1,
          column: node.start_column + 1,
          end_line: node.end_line + 1,
          end_column: node.end_column + 1
        )
      end
    end
  end
end
