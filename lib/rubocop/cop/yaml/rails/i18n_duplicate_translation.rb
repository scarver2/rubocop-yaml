# lib/rubocop/cop/yaml/rails/i18n_duplicate_translation.rb
# frozen_string_literal: true

require "pathname"

require_relative "i18n_base"

module RuboCop
  module Cop
    module YAML
      module Rails
        class I18nDuplicateTranslation < I18nBase
          Finding = Struct.new(:entry, :others, :message, keyword_init: true)
          MSG = "Translation `%<locale>s.%<path>s` is also defined at %<locations>s."

          def on_new_investigation
            configured_findings.each do |finding|
              add_entry_offense(finding.entry, finding.message) if current_file?(finding.entry)
            end
          end

          def findings(index, excluded_files: [], ignored_paths: [])
            index.locales.flat_map do |locale|
              index.translations_for(locale).sort.flat_map do |path, entries|
                included = included_entries(entries, excluded_files).reject { |entry| entry.type == :mapping }
                collision_findings(locale, path, included, ignored_paths)
              end
            end
          end

          private

          def configured_findings
            findings(
              locale_index,
              excluded_files: Array(cop_config.fetch("ExcludedLocaleFiles", [])),
              ignored_paths: ignored_paths
            )
          end

          def included_entries(entries, excluded_files)
            entries.reject do |entry|
              excluded_files.any? { |pattern| file_match?(pattern, entry.file) }
            end
          end

          def file_match?(pattern, file)
            relative = Pathname(file).relative_path_from(Pathname(Dir.pwd)).to_s
            File.fnmatch?(pattern, relative, File::FNM_PATHNAME | File::FNM_EXTGLOB) ||
              File.fnmatch?(pattern, file, File::FNM_PATHNAME | File::FNM_EXTGLOB)
          rescue ArgumentError
            File.fnmatch?(pattern, file, File::FNM_EXTGLOB)
          end

          def collision_findings(locale, path, entries, ignored_paths)
            return [] if ignored_paths.any? { |pattern| File.fnmatch?(pattern, path, File::FNM_EXTGLOB) }
            return [] unless entries.map(&:file).uniq.length > 1

            entries.map { |entry| collision_finding(locale, path, entry, entries - [entry]) }
          end

          def collision_finding(locale, path, entry, others)
            locations = others.sort_by { |other| [other.file, other.line, other.column] }
                              .map { |other| "#{other.file}:#{other.line}:#{other.column}" }.join(", ")
            Finding.new(
              entry: entry, others: others,
              message: format(MSG, locale: locale, path: path, locations: locations)
            )
          end
        end
      end
    end
  end
end
