# lib/rubocop/cop/yaml/lint/invalid_syntax.rb
# frozen_string_literal: true

require_relative "../base"

module RuboCop
  module Cop
    module YAML
      module Lint
        class InvalidSyntax < Base
          MSG = "Invalid YAML syntax: %<message>s"

          def on_new_investigation
            diagnostic = yaml_result.diagnostic
            return unless diagnostic

            add_offense(
              source_range(diagnostic.line, diagnostic.column),
              message: format(MSG, message: diagnostic.message)
            )
          end
        end
      end
    end
  end
end
