# lib/rubocop/cop/yaml/style/key_ordering.rb
# frozen_string_literal: true

require_relative "../base"

module RuboCop
  module Cop
    module YAML
      module Style
        class KeyOrdering < Base
          MSG = "Place `%<key>s` before `%<previous>s` according to the configured key order."

          def on_new_investigation # rubocop:disable Metrics/AbcSize
            return unless yaml_result.success?

            violations(yaml_result.stream, style: style, keys: configured_keys).each do |key, previous|
              add_offense(
                source_range(key.location.line, key.location.column, key.value.length),
                message: format(MSG, key: key.value, previous: previous.value)
              )
            end
          end

          def violations(root, style:, keys: [])
            mappings(root).flat_map do |mapping|
              scalar_keys = mapping.children.each_slice(2).map(&:first)
              next [] unless scalar_keys.all? { |key| sortable?(key) }

              ordering_violations(scalar_keys, style, keys)
            end
          end

          private

          def mappings(node)
            own = node.type == :mapping ? [node] : []
            own + node.children.flat_map { |child| mappings(child) }
          end

          def ordering_violations(keys, style, configured)
            ranked = ranked_keys(keys, style, configured)
            ranked.each_cons(2).filter_map { |previous, key| [key.last, previous.last] if key.first < previous.first }
          end

          def ranked_keys(keys, style, configured)
            return keys.map { |key| [key.value.downcase, key] } if style.to_s == "alphabetical"

            indexes = configured.each_with_index.to_h
            keys.filter_map { |key| [indexes[key.value], key] if indexes.key?(key.value) }
          end

          def sortable?(key)
            key&.type == :scalar && key.value != "<<"
          end

          def style
            cop_config.fetch("EnforcedStyle", "alphabetical")
          end

          def configured_keys
            cop_config.fetch("Keys", [])
          end
        end
      end
    end
  end
end
