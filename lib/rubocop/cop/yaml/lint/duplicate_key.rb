# lib/rubocop/cop/yaml/lint/duplicate_key.rb
# frozen_string_literal: true

require_relative "../base"

module RuboCop
  module Cop
    module YAML
      module Lint
        class DuplicateKey < Base
          MSG = "Duplicate key `%<key>s`; first declared on line %<line>d."

          def on_new_investigation # rubocop:disable Metrics/AbcSize
            return unless yaml_result.success?

            duplicates(yaml_result.stream).each do |key, first|
              add_offense(
                source_range(key.location.line, key.location.column, key.value.length),
                message: format(MSG, key: key.value, line: first.location.line)
              )
            end
          end

          def duplicates(root)
            find_mappings(root).flat_map { |mapping| mapping_duplicates(mapping) }
          end

          private

          def find_mappings(node)
            matches = node.type == :mapping ? [node] : []
            matches + node.children.flat_map { |child| find_mappings(child) }
          end

          def mapping_duplicates(mapping)
            seen = {}
            mapping.children.each_slice(2).filter_map do |key, _value|
              next unless scalar_key?(key)

              identity = [key.tag, key.value]
              first = seen[identity]
              seen[identity] ||= key
              [key, first] if first
            end
          end

          def scalar_key?(key)
            key&.type == :scalar && key.value != "<<"
          end
        end
      end
    end
  end
end
