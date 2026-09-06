# lib/rubocop/yaml/plugin.rb
# frozen_string_literal: true

require "lint_roller"
require "pathname"

require_relative "processed_source"

module RuboCop
  module Yaml
    class Plugin < LintRoller::Plugin
      def about
        LintRoller::About.new(
          name: "rubocop-yaml",
          version: VERSION,
          homepage: "https://github.com/scarver2/rubocop-yaml",
          description: "YAML analysis with native RuboCop offenses"
        )
      end

      def supported?(context)
        context.engine == :rubocop
      end

      def rules(_context)
        LintRoller::Rules.new(
          type: :path,
          config_format: :rubocop,
          value: Pathname(__dir__).join("../../../config/default.yml")
        )
      end
    end
  end
end
