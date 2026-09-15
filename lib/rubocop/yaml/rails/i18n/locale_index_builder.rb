# lib/rubocop/yaml/rails/i18n/locale_index_builder.rb
# frozen_string_literal: true

module RuboCop
  module Yaml
    module Rails
      module I18n
        class LocaleIndexBuilder
          Context = Struct.new(:locale, :file, :document, :anchors, :resolving, keyword_init: true)

          def initialize(root:, patterns:, parser:)
            @root = File.expand_path(root)
            @patterns = Array(patterns).freeze
            @parser = parser
          end

          def build
            reset
            files.each { |file| index_file(file) }
            LocaleIndex.new(entries: entries, diagnostics: diagnostics, files: files)
          end

          private

          attr_reader :diagnostics, :entries, :files, :parser, :patterns, :root

          def reset
            @entries = {}
            @diagnostics = []
            @files = patterns.flat_map { |pattern| Dir.glob(File.join(root, pattern)) }
                             .select { |path| File.file?(path) }.uniq.sort
          end

          def index_file(file)
            result = parser.parse(File.read(file), path: file)
            return diagnostics << result.diagnostic unless result.success?

            result.stream.children.each_with_index { |document, index| index_document(document, file, index) }
          end

          def index_document(document, file, document_index)
            root_node = document.children.first
            return unless root_node&.type == :mapping

            context = Context.new(file: file, document: document_index, anchors: anchors(root_node), resolving: [])
            root_node.children.each_slice(2) { |locale_node, tree_node| index_locale(context, locale_node, tree_node) }
          end

          def index_locale(context, locale_node, tree_node)
            return unless locale_node&.type == :scalar

            locale = locale_node.value.to_s
            entries[locale] ||= {}
            index_tree(context.dup.tap { |copy| copy.locale = locale }, [], tree_node)
          end

          def index_tree(context, prefix, node)
            resolved = resolve_alias(node, context)
            return unless resolved

            node, context = resolved
            return unless node.type == :mapping

            node.children.each_slice(2) do |key_node, value_node|
              index_pair(context, prefix, key_node, value_node) if key_node&.type == :scalar
            end
          end

          def index_pair(context, prefix, key_node, value_node)
            path = [*prefix, key_node.value.to_s]
            add_entry(context, path, key_node, value_node)
            index_tree(context, path, value_node)
          end

          def add_entry(context, path, key_node, value_node)
            dotted_path = path.join(".")
            entry = build_entry(context, dotted_path, key_node, value_node)
            (entries.fetch(context.locale)[dotted_path] ||= []) << entry
          end

          def build_entry(context, dotted_path, key_node, value_node)
            LocaleIndex::Entry.new(
              locale: context.locale, path: dotted_path, file: context.file,
              line: key_node.location.line, column: key_node.location.column,
              type: value_node.type, value: value_node.value, node: value_node,
              document: context.document
            ).freeze
          end

          def anchors(node, found = {})
            found[node.anchor] = node if node.anchor && node.type != :alias
            node.children.each { |child| anchors(child, found) }
            found
          end

          def resolve_alias(node, context)
            return unless node
            return [node, context] unless node.type == :alias
            return if context.resolving.include?(node.anchor)

            target = context.anchors[node.anchor]
            return unless target

            resolved_context = context.dup
            resolved_context.resolving = [*context.resolving, node.anchor]
            [target, resolved_context]
          end
        end
      end
    end
  end
end
