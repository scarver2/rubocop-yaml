<!-- README.md -->
# RuboCop YAML

RuboCop YAML brings deterministic YAML syntax, style, schema, and Rails-configuration checks into RuboCop.

## Status

Early development. The plugin foundation is available; cops are being added in focused releases.

## Installation

Add `gem "rubocop-yaml", require: false` to your Gemfile, then configure:

```yaml
plugins:
  - rubocop-yaml
```

RuboCop 1.72 or newer is required because RuboCop YAML uses the current plugin API.

## Development and testing

Run `bin/setup`, then `bin/ci`. Use `bin/rspec` and `bin/rubocop` with passthrough arguments for focused checks. See [the documentation index](docs/README.md) for architecture and contribution notes.

## Project layout

- `lib/` contains the plugin and its public API.
- `config/` contains the plugin's default RuboCop configuration.
- `spec/` contains executable behavior and integration coverage.
- `docs/` contains project documentation.

## License

RuboCop YAML is available under the [MIT License](LICENSE).

Source: [github.com/scarver2/rubocop-yaml](https://github.com/scarver2/rubocop-yaml)

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
