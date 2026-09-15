# lib/rubocop/cop/yaml/rails/i18n_pluralization_contract.rb
# frozen_string_literal: true

require_relative "i18n_base"

module RuboCop
  module Cop
    module YAML
      module Rails
        class I18nPluralizationContract < I18nBase
          Finding = Struct.new(:entry, :locale, :path, :message, keyword_init: true)
          Analysis = Struct.new(:index, :locale, :path, :sources, :categories, keyword_init: true)
          MISSING = "Locale `%<locale>s` pluralization `%<path>s` is missing categories: %<categories>s."
          COUNT = "Locale `%<locale>s` pluralization `%<path>s.%<category>s` must interpolate `%%{count}`."

          def on_new_investigation
            configured_findings.each do |finding|
              add_entry_offense(finding.entry, finding.message) if current_file?(finding.entry)
            end
          end

          def findings(index, required_categories:, count_required_categories: {}, ignored_paths: [])
            normalized_requirements(required_categories).flat_map do |locale, required|
              plural_maps(index, locale, ignored_paths).flat_map do |path, entries, categories|
                analysis = Analysis.new(
                  index: index, locale: locale, path: path, sources: entries, categories: categories
                )
                map_findings(analysis, required, count_required_categories)
              end
            end
          end

          private

          def configured_findings
            findings(
              locale_index,
              required_categories: cop_config.fetch("RequiredCategories", default_requirements),
              count_required_categories: cop_config.fetch("CountRequiredCategories", {}),
              ignored_paths: ignored_paths
            )
          end

          def normalized_requirements(requirements)
            requirements.to_h { |locale, categories| [locale.to_s, Array(categories).map(&:to_s).uniq.sort] }
          end

          def plural_maps(index, locale, ignored)
            index.translations_for(locale).sort.filter_map do |path, entries|
              next unless entries.any? { |entry| entry.type == :mapping }
              next if ignored.any? { |pattern| File.fnmatch?(pattern, path, File::FNM_EXTGLOB) }

              categories = child_categories(index, locale, path)
              [path, entries, categories] if plural_map?(categories)
            end
          end

          def child_categories(index, locale, path)
            prefix = "#{path}."
            index.translations_for(locale).keys.filter_map do |candidate|
              child = candidate.delete_prefix(prefix)
              child if candidate.start_with?(prefix) && !child.include?(".")
            end.uniq.sort
          end

          def plural_map?(categories)
            allowed = RuboCop::Yaml::Rails::I18n::Pluralization::CATEGORY_KEYS
            !categories.empty? && (categories - allowed).empty?
          end

          def default_requirements
            { "en" => RuboCop::Yaml::Rails::I18n::Pluralization.default_categories }
          end

          def map_findings(analysis, required, count_requirements)
            findings = missing_category_findings(
              analysis.locale, analysis.path, analysis.sources, required - analysis.categories
            )
            count_categories = analysis.categories & categories_for(count_requirements, analysis.locale)
            findings + count_findings(analysis, count_categories)
          end

          def missing_category_findings(locale, path, entries, missing)
            return [] if missing.empty?

            anchor = entries.find { |entry| entry.type == :mapping }
            [Finding.new(
              entry: anchor, locale: locale, path: path,
              message: format(MISSING, locale: locale, path: path, categories: missing.join(", "))
            )]
          end

          def categories_for(requirements, locale)
            Array(requirements[locale] || requirements[locale.to_sym]).map(&:to_s)
          end

          def count_findings(analysis, categories)
            categories.flat_map do |category|
              category_entries(analysis, category).filter_map do |entry|
                next if RuboCop::Yaml::Rails::I18n::Interpolation.placeholders(entry.value).include?("count")

                count_finding(analysis, category, entry)
              end
            end
          end

          def count_finding(analysis, category, entry)
            Finding.new(
              entry: entry, locale: analysis.locale, path: analysis.path,
              message: format(COUNT, locale: analysis.locale, path: analysis.path, category: category)
            )
          end

          def category_entries(analysis, category)
            analysis.index.entries_for(
              analysis.locale, "#{analysis.path}.#{category}"
            ).select { |entry| entry.type == :scalar }
          end
        end
      end
    end
  end
end
