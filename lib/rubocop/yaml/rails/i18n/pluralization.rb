# lib/rubocop/yaml/rails/i18n/pluralization.rb
# frozen_string_literal: true

module RuboCop
  module Yaml
    module Rails
      module I18n
        module Pluralization
          CATEGORY_KEYS = %w[0 1 few many one other two zero].freeze

          def self.default_categories
            backend = ::I18n::Backend::Simple.new
            backend.store_translations(:en, rubocop_yaml_probe: { one: "one", other: "other" })
            [1, 2].map { |count| backend.translate(:en, :rubocop_yaml_probe, count: count) }.uniq.sort
          end
        end
      end
    end
  end
end
