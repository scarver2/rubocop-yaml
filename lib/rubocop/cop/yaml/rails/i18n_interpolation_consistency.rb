# lib/rubocop/cop/yaml/rails/i18n_interpolation_consistency.rb
# frozen_string_literal: true

require_relative "i18n_base"

module RuboCop
  module Cop
    module YAML
      module Rails
        class I18nInterpolationConsistency < I18nBase
          Finding = Struct.new(:entry, :locale, :path, :missing, :extra, :message, keyword_init: true)

          def on_new_investigation
            configured_findings.each do |finding|
              add_entry_offense(finding.entry, finding.message) if current_file?(finding.entry)
            end
          end

          def findings(index, reference_locale:, locales: [], ignored_locales: [], ignored_paths: [])
            reference = scalar_entries(index, reference_locale)
            targets(index, reference_locale, locales, ignored_locales).flat_map do |locale|
              interpolation_findings(reference, scalar_entries(index, locale), locale, ignored_paths)
            end
          end

          def placeholders(value)
            RuboCop::Yaml::Rails::I18n::Interpolation.placeholders(value)
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

          def scalar_entries(index, locale)
            index.translations_for(locale).transform_values { |entries| entries.select { |entry| entry.type == :scalar } }
          end

          def targets(index, reference, configured, ignored)
            locales = configured.empty? ? index.locales : configured
            locales.reject { |locale| locale == reference || ignored.include?(locale) }
          end

          def interpolation_findings(reference, target, locale, ignored)
            (reference.keys & target.keys).sort.filter_map do |path|
              next if ignored.any? { |pattern| File.fnmatch?(pattern, path, File::FNM_EXTGLOB) }

              compare_path(reference.fetch(path).first, target.fetch(path), locale, path)
            end.flatten
          end

          def compare_path(reference, targets, locale, path)
            expected = placeholders(reference.value)
            targets.filter_map do |entry|
              actual = placeholders(entry.value)
              build_finding(entry, locale, path, expected, actual) unless expected == actual
            end
          end

          def build_finding(entry, locale, path, expected, actual)
            missing = expected - actual
            extra = actual - expected
            Finding.new(
              entry: entry, locale: locale, path: path, missing: missing, extra: extra,
              message: contract_message(locale, path, missing, extra)
            )
          end

          def contract_message(locale, path, missing, extra)
            if missing.one? && extra.one?
              "Locale `#{locale}` translation `#{path}` replaces `%{#{missing.first}}` with `%{#{extra.first}}`."
            else
              details = []
              details << "missing #{format_placeholders(missing)}" unless missing.empty?
              details << "extra #{format_placeholders(extra)}" unless extra.empty?
              "Locale `#{locale}` translation `#{path}` has inconsistent interpolation: #{details.join('; ')}."
            end
          end

          def format_placeholders(names)
            names.map { |name| "%{#{name}}" }.join(", ")
          end
        end
      end
    end
  end
end
