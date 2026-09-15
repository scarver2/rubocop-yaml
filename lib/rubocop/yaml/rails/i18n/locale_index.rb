# lib/rubocop/yaml/rails/i18n/locale_index.rb
# frozen_string_literal: true

module RuboCop
  module Yaml
    module Rails
      module I18n
        class LocaleIndex
          DEFAULT_PATTERNS = %w[config/locales/**/*.yaml config/locales/**/*.yml].freeze
          EMPTY_ENTRIES = [].freeze
          EMPTY_TRANSLATIONS = {}.freeze

          Entry = Struct.new(
            :locale,
            :path,
            :file,
            :line,
            :column,
            :type,
            :value,
            :node,
            :document,
            keyword_init: true
          )

          attr_reader :diagnostics, :files

          def self.build(root: Dir.pwd, patterns: DEFAULT_PATTERNS, parser: Parser.new)
            LocaleIndexBuilder.new(root: root, patterns: patterns, parser: parser).build
          end

          def initialize(entries:, diagnostics:, files:)
            @entries = freeze_entries(entries)
            @diagnostics = diagnostics.freeze
            @files = files.freeze
            freeze
          end

          def locales
            entries.keys.freeze
          end

          def translations_for(locale)
            entries.fetch(locale.to_s, EMPTY_TRANSLATIONS)
          end

          def entries_for(locale, path)
            translations_for(locale).fetch(path.to_s, EMPTY_ENTRIES)
          end

          def each_entry(&block)
            return enum_for(__method__) unless block_given?

            entries.each_value do |translations|
              translations.each_value do |path_entries|
                path_entries.each(&block)
              end
            end
          end

          private

          attr_reader :entries

          def freeze_entries(entries)
            entries.each_value do |translations|
              translations.each_value(&:freeze)
              translations.freeze
            end
            entries.freeze
          end
        end
      end
    end
  end
end
