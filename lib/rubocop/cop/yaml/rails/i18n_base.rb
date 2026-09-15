# lib/rubocop/cop/yaml/rails/i18n_base.rb
# frozen_string_literal: true

require_relative "../base"

module RuboCop
  module Cop
    module YAML
      module Rails
        class I18nBase < Base
          private

          def locale_index
            @locale_index ||= RuboCop::Yaml::Rails::I18n::LocaleIndex.build(
              root: Dir.pwd,
              patterns: cop_config.fetch("LocaleFiles", RuboCop::Yaml::Rails::I18n::LocaleIndex::DEFAULT_PATTERNS)
            )
          end

          def reference_locale
            cop_config.fetch("ReferenceLocale", "en").to_s
          end

          def configured_locales
            Array(cop_config.fetch("Locales", [])).map(&:to_s)
          end

          def ignored_locales
            Array(cop_config.fetch("IgnoredLocales", [])).map(&:to_s)
          end

          def ignored_paths
            Array(cop_config.fetch("IgnoredPaths", []))
          end

          def current_file?(entry)
            File.expand_path(processed_source.path) == File.expand_path(entry.file)
          end

          def add_entry_offense(entry, message)
            key = entry.path.split(".").last
            add_offense(source_range(entry.line, entry.column, key.length), message: message)
          end
        end
      end
    end
  end
end
