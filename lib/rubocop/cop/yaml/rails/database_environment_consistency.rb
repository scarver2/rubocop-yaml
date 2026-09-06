# lib/rubocop/cop/yaml/rails/database_environment_consistency.rb
# frozen_string_literal: true

require_relative "../base"

module RuboCop
  module Cop
    module YAML
      module Rails
        class DatabaseEnvironmentConsistency < Base
          Finding = Struct.new(:node, :message, keyword_init: true)
          MISSING_ENV = "Define the `%<environment>s` database environment."
          MISSING_KEY = "Database environment `%<environment>s` is missing required key `%<key>s`."

          def on_new_investigation
            return unless database_config? && yaml_result.success?

            configured_findings.each do |finding|
              node = finding.node
              add_offense(source_range(node.location.line, node.location.column, node.value&.length || 1), message: finding.message)
            end
          end

          def findings(stream, required_environments:, required_keys:, allow_merge_keys: true)
            root = stream.children.first&.children&.first
            return [] unless root&.type == :mapping

            entries = root.children.each_slice(2).to_h { |key, value| [key.value, [key, value]] }
            anchors = anchor_mappings(root)
            required_environments.flat_map do |environment|
              environment_findings(root, entries, anchors, environment, required_keys, allow_merge_keys)
            end
          end

          private

          def database_config?
            File.basename(processed_source.path).match?(/\Adatabase\.ya?ml\z/)
          end

          def configured_findings
            findings(
              yaml_result.stream,
              required_environments: cop_config.fetch("RequiredEnvironments", %w[development test production]),
              required_keys: cop_config.fetch("RequiredKeys", %w[adapter database]),
              allow_merge_keys: cop_config.fetch("AllowMergeKeys", true)
            )
          end

          def environment_findings(root, entries, anchors, environment, required_keys, allow_merge_keys) # rubocop:disable Metrics/ParameterLists
            key, mapping = entries[environment]
            return [Finding.new(node: root, message: format(MISSING_ENV, environment: environment))] unless key
            return required_keys.map { |required| missing_key(key, environment, required) } unless mapping.type == :mapping

            present = effective_keys(mapping, anchors, allow_merge_keys)
            required_keys.filter_map { |required| missing_key(key, environment, required) unless present.include?(required) }
          end

          def missing_key(node, environment, key)
            Finding.new(node: node, message: format(MISSING_KEY, environment: environment, key: key))
          end

          def anchor_mappings(node)
            own = node.type == :mapping && node.anchor ? { node.anchor => node } : {}
            node.children.each_with_object(own) { |child, anchors| anchors.merge!(anchor_mappings(child)) }
          end

          def effective_keys(mapping, anchors, allow_merge_keys)
            keys = Set.new
            mapping.children.each_slice(2) do |key, value|
              if key.value == "<<" && allow_merge_keys
                merged = anchors[value.anchor]
                keys.merge(effective_keys(merged, anchors, false)) if merged
              else
                keys << key.value
              end
            end
            keys
          end
        end
      end
    end
  end
end
