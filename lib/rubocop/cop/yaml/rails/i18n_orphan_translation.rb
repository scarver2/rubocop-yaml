# lib/rubocop/cop/yaml/rails/i18n_orphan_translation.rb
# frozen_string_literal: true

require_relative "i18n_base"

module RuboCop
  module Cop
    module YAML
      module Rails
        class I18nOrphanTranslation < I18nBase
          Finding = Struct.new(:entry, :locale, :path, :message, keyword_init: true)
          Settings = Struct.new(:reference, :locales, :ignored_locales, :ignored_paths, :locale_ignored_paths, keyword_init: true)
          MSG = "Locale `%<locale>s` translation `%<path>s` does not exist in reference locale `%<reference>s`."

          def on_new_investigation
            configured_findings.each do |finding|
              add_entry_offense(finding.entry, finding.message) if current_file?(finding.entry)
            end
          end

          def findings(index, reference_locale:, **options)
            settings = build_settings(reference_locale, options)
            reference_paths = leaf_paths(index, settings.reference)
            target_locales(index, settings.reference, settings.locales, settings.ignored_locales).flat_map do |locale|
              orphan_findings(index, reference_paths, locale, settings)
            end
          end

          private

          def configured_findings
            findings(
              locale_index,
              reference_locale: reference_locale,
              locales: configured_locales,
              ignored_locales: ignored_locales,
              ignored_paths: ignored_paths,
              locale_ignored_paths: cop_config.fetch("LocaleIgnoredPaths", {})
            )
          end

          def build_settings(reference, options)
            Settings.new(
              reference: reference,
              locales: options.fetch(:locales, []),
              ignored_locales: options.fetch(:ignored_locales, []),
              ignored_paths: options.fetch(:ignored_paths, []),
              locale_ignored_paths: options.fetch(:locale_ignored_paths, {})
            )
          end

          def leaf_paths(index, locale)
            index.translations_for(locale).filter_map do |path, entries|
              path if entries.any? { |entry| entry.type != :mapping }
            end
          end

          def target_locales(index, reference, configured, ignored)
            locales = configured.empty? ? index.locales : configured
            locales.reject { |locale| locale == reference || ignored.include?(locale) }
          end

          def orphan_findings(index, reference_paths, locale, settings)
            paths = orphan_paths(index, reference_paths, locale, ignored_patterns(settings, locale))
            paths.sort.flat_map do |path|
              index.entries_for(locale, path).reject { |entry| entry.type == :mapping }.map do |entry|
                orphan_finding(entry, settings.reference)
              end
            end
          end

          def orphan_paths(index, reference_paths, locale, patterns)
            leaf_paths(index, locale).reject do |path|
              reference_paths.include?(path) || ignored?(path, patterns)
            end
          end

          def ignored_patterns(settings, locale)
            locale_patterns = settings.locale_ignored_paths
            [*settings.ignored_paths, *Array(locale_patterns[locale]), *Array(locale_patterns[locale.to_sym])]
          end

          def ignored?(path, patterns)
            patterns.any? { |pattern| File.fnmatch?(pattern, path, File::FNM_EXTGLOB) }
          end

          def orphan_finding(entry, reference)
            Finding.new(
              entry: entry, locale: entry.locale, path: entry.path,
              message: format(MSG, locale: entry.locale, path: entry.path, reference: reference)
            )
          end
        end
      end
    end
  end
end
