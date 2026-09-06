# lib/rubocop/cop/yaml/style/key_grouping.rb
# frozen_string_literal: true

require_relative "../base"

module RuboCop
  module Cop
    module YAML
      module Style
        class KeyGrouping < Base
          Finding = Struct.new(:key, :message, keyword_init: true)
          ORDER_MSG = "Place `%<key>s` with the earlier `%<group>s` key group."
          SPACE_MSG = "Separate the `%<group>s` key group with a blank line."

          def on_new_investigation # rubocop:disable Metrics/AbcSize
            return unless yaml_result.success?

            findings(yaml_result.stream, settings).each do |finding|
              key = finding.key
              add_offense(source_range(key.location.line, key.location.column, key.value.length), message: finding.message)
            end
          end

          def findings(root, options)
            groups = options.fetch("Groups")
            ranks = group_ranks(groups)
            mappings(root).flat_map do |mapping, path|
              next [] unless in_scope?(path, options.fetch("Scopes", ["*"]))

              keys = mapping.children.each_slice(2).map(&:first)
              keys = keys.select { |key| key.type == :scalar && key.value != "<<" }
              ranked_findings(keys, groups, ranks, options)
            end
          end

          private

          def settings
            cop_config.slice("Groups", "Scopes", "UnknownKeys", "RequireBlankLines")
          end

          def group_ranks(groups)
            groups.each_with_index.with_object({}) do |(group, index), ranks|
              group.fetch("Keys").each { |key| ranks[key] = [index, group.fetch("Name")] }
            end
          end

          def mappings(node, path = []) # rubocop:disable Metrics/AbcSize
            own = node.type == :mapping ? [[node, path]] : []
            return own + node.children.flat_map { |child| mappings(child, path) } unless node.type == :mapping

            children = node.children.each_slice(2).flat_map do |key, value|
              key_path = key.type == :scalar ? path + [key.value] : path
              mappings(value, key_path)
            end
            own + children
          end

          def in_scope?(path, scopes)
            scopes.include?("*") || scopes.include?(path.join("."))
          end

          def ranked_findings(keys, groups, ranks, options)
            unknown_rank = options.fetch("UnknownKeys", "last") == "last" ? groups.length : nil
            ranked = keys.filter_map do |key|
              rank, name = ranks.fetch(key.value, [unknown_rank, "unlisted"])
              [rank, name, key] if rank
            end
            order_findings(ranked) + spacing_findings(ranked, options.fetch("RequireBlankLines", false))
          end

          def order_findings(ranked)
            ranked.each_cons(2).filter_map do |previous, current|
              next unless current.first < previous.first

              Finding.new(key: current.last, message: format(ORDER_MSG, key: current.last.value, group: current[1]))
            end
          end

          def spacing_findings(ranked, required)
            return [] unless required

            ranked.each_cons(2).filter_map do |previous, current|
              next if previous.first == current.first || current.last.location.line > previous.last.location.end_line + 1

              Finding.new(key: current.last, message: format(SPACE_MSG, group: current[1]))
            end
          end
        end
      end
    end
  end
end
