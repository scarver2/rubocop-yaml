# lib/rubocop/yaml.rb
# frozen_string_literal: true

require_relative "yaml/parser"
# Plugin registration reads VERSION while the class is defined.
require_relative "yaml/version"
require_relative "yaml/plugin"
require_relative "cop/yaml/lint/duplicate_key"
require_relative "cop/yaml/lint/invalid_syntax"
