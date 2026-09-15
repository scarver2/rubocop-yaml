# lib/rubocop/yaml/rails/i18n/interpolation.rb
# frozen_string_literal: true

module RuboCop
  module Yaml
    module Rails
      module I18n
        module Interpolation
          PLACEHOLDER = /(?<!%)%\{([a-zA-Z_]\w*)\}/

          module_function

          def placeholders(value)
            value.to_s.scan(PLACEHOLDER).flatten.uniq.sort
          end
        end
      end
    end
  end
end
