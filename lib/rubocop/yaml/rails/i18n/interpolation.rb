# lib/rubocop/yaml/rails/i18n/interpolation.rb
# frozen_string_literal: true

module RuboCop
  module Yaml
    module Rails
      module I18n
        module Interpolation
          def self.placeholders(value)
            pattern = Regexp.union(::I18n.config.interpolation_patterns)
            value.to_s.scan(pattern).filter_map { |captures| Array(captures).compact.first }.map(&:to_s).uniq.sort
          end

          def self.reserved?(placeholder)
            ::I18n::RESERVED_KEYS.include?(placeholder.to_sym)
          end
        end
      end
    end
  end
end
