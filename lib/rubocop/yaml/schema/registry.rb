# lib/rubocop/yaml/schema/registry.rb
# frozen_string_literal: true

module RuboCop
  module Yaml
    module Schema
      class Registry
        Entry = Struct.new(:name, :version, :path, keyword_init: true)

        def resolve(path)
          case path
          when %r{(?:\A|/)(?:compose|docker-compose)\.ya?ml\z}
            entry("Docker Compose", "compose-spec-2026-08", "compose.json")
          when %r{(?:\A|/)\.github/workflows/[^/]+\.ya?ml\z}
            entry("GitHub Actions", "schema-store-2026-08", "github-actions.json")
          end
        end

        private

        def entry(name, version, filename)
          Entry.new(
            name: name,
            version: version,
            path: File.expand_path("../../../../config/schemas/#{filename}", __dir__)
          )
        end
      end
    end
  end
end
