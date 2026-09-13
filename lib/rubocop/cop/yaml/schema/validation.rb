# lib/rubocop/cop/yaml/schema/validation.rb
# frozen_string_literal: true

require_relative "../base"

module RuboCop
  module Cop
    module YAML
      module Schema
        class Validation < Base
          MSG = "Schema violation at `%<pointer>s`: %<message>s"

          def on_new_investigation
            findings.each do |finding|
              add_offense(
                source_range(finding.line, finding.column),
                message: format(MSG, pointer: finding.pointer.empty? ? "/" : finding.pointer, message: finding.message)
              )
            end
            debug_schema
          rescue RuboCop::Yaml::Schema::Validator::ConfigurationError => e
            add_offense(source_range(1, 1), message: "Schema configuration error: #{e.message}")
          end

          private

          def findings
            validator.validate(
              source: processed_source.raw_source,
              path: processed_source.path,
              schemas: cop_config.fetch("Schemas", {}),
              root: Dir.pwd,
              autodetect: cop_config.fetch("AutoDetect", true)
            )
          end

          def validator
            @validator ||= RuboCop::Yaml::Schema::Validator.new
          end

          def debug_schema
            return unless cop_config.fetch("Debug", false) && validator.selected_schema

            entry = validator.selected_schema
            warn("rubocop-yaml: #{processed_source.path} uses #{entry.name} schema #{entry.version} (#{entry.path})")
          end
        end
      end
    end
  end
end
