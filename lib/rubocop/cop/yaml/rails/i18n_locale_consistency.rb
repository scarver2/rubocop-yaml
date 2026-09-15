# lib/rubocop/cop/yaml/rails/i18n_locale_consistency.rb
# frozen_string_literal: true

require_relative "i18n_base"

module RuboCop
  module Cop
    module YAML
      module Rails
        class I18nLocaleConsistency < I18nBase
          Finding = Struct.new(:entry, :locale, :path, :message, keyword_init: true)
          MSG = "Locale `%<locale>s` is missing translation `%<path>s` from reference locale `%<reference>s`."

          def on_new_investigation
            configured_findings.each do |finding|
              add_entry_offense(finding.entry, finding.message) if current_file?(finding.entry)
            end
          end

          def findings(index, reference_locale:, locales: [], ignored_locales: [], ignored_paths: [])
            reference_paths = leaf_paths(index, reference_locale)
            target_locales(index, reference_locale, locales, ignored_locales).flat_map do |locale|
              missing = reference_paths - leaf_paths(index, locale)
              missing_paths(index, locale, missing, ignored_paths).map do |path|
                missing_finding(index, reference_locale, locale, path)
              end
            end
          end

          private

          def configured_findings
            findings(
              locale_index,
              reference_locale: reference_locale,
              locales: configured_locales,
              ignored_locales: ignored_locales,
              ignored_paths: ignored_paths
            )
          end

          def leaf_paths(index, locale)
            index.translations_for(locale).filter_map do |path, entries|
              path if entries.any? { |entry| entry.type != :mapping }
            end.to_set
          end

          def target_locales(index, reference, configured, ignored)
            locales = configured.empty? ? index.locales : configured
            locales.reject { |locale| locale == reference || ignored.include?(locale) }
          end

          def missing_paths(index, locale, paths, ignored)
            translations = index.translations_for(locale)
            paths.reject { |path| ignored_path?(path, ignored) }
                 .map { |path| first_missing_path(path, translations) }.uniq.sort
          end

          def ignored_path?(path, patterns)
            patterns.any? { |pattern| File.fnmatch?(pattern, path, File::FNM_EXTGLOB) }
          end

          def first_missing_path(path, translations)
            parts = path.split(".")
            (1..parts.length).map { |length| parts.first(length).join(".") }
                             .find { |candidate| !translations.key?(candidate) }
          end

          def missing_finding(index, reference, locale, path)
            entry = locale_anchor(index, locale) || reference_anchor(index, reference, path)
            Finding.new(
              entry: entry, locale: locale, path: path,
              message: format(MSG, locale: locale, path: path, reference: reference)
            )
          end

          def locale_anchor(index, locale)
            index.translations_for(locale).values.flatten.min_by { |entry| [entry.file, entry.line, entry.column] }
          end

          def reference_anchor(index, locale, path)
            translations = index.translations_for(locale)
            translations[path]&.first || translations.values.flatten.first
          end
        end
      end
    end
  end
end
