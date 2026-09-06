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
          rescue RuboCop::Yaml::Schema::Validator::ConfigurationError => e
            add_offense(source_range(1, 1), message: "Schema configuration error: #{e.message}")
          end

          private

          def findings
            validator.validate(
              source: processed_source.raw_source,
              path: processed_source.path,
              schemas: cop_config.fetch("Schemas", {}),
              root: Dir.pwd
            )
          end

          def validator
            @validator ||= RuboCop::Yaml::Schema::Validator.new
          end
        end
      end
    end
  end
end
