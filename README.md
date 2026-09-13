<!-- README.md -->
# RuboCop YAML

RuboCop YAML brings deterministic YAML syntax, style, schema, and Rails-configuration checks into RuboCop while preserving comments, anchors, aliases, and document structure.

## Status

Version 0.1.0 is the first public release. Its existing semantics are the baseline for real-world dogfooding; new behavior should be driven by confirmed usage rather than speculative fixtures.

## Requirements

- Ruby 3.2 or newer
- RuboCop 1.72 or newer and earlier than 2.0

The gem is framework-independent. Rails is not a runtime dependency; Rails-specific cops operate on configuration files by path and structure.

## Installation

Add the gem to the development and test groups in your `Gemfile`:

```ruby
group :development, :test do
  gem "rubocop-yaml", "~> 0.1", require: false
end
```

Run `bundle install`, then register the plugin in `.rubocop.yml`:

```yaml
plugins:
  - rubocop-yaml
```

RuboCop YAML automatically includes `**/*.yml` and `**/*.yaml` files.

## Cops

| Cop | Default | Purpose |
| --- | ---: | --- |
| `YAML/Lint/InvalidSyntax` | Enabled | Reports malformed YAML at the parser location |
| `YAML/Lint/DuplicateKey` | Enabled | Reports silent duplicate scalar keys |
| `YAML/Style/KeyOrdering` | Disabled | Enforces alphabetical or configured key order |
| `YAML/Style/KeyGrouping` | Disabled | Enforces semantic groups and optional spacing |
| `YAML/Schema/Validation` | Disabled | Validates against local or autodetected JSON Schemas |
| `YAML/Rails/DatabaseEnvironmentConsistency` | Enabled for `config/database.yml` | Reports missing Rails environments and required keys |

## Configuration examples

Configure explicit key order without enabling autocorrection:

```yaml
YAML/Style/KeyOrdering:
  Enabled: true
  EnforcedStyle: configured
  Keys:
    - name
    - image
    - environment
    - volumes
```

Map project files to local JSON Schemas:

```yaml
YAML/Schema/Validation:
  Enabled: true
  Schemas:
    "config/services/*.yml": "schemas/service.json"
```

With `AutoDetect: true`, schema validation recognizes Compose files and `.github/workflows/*.yml` using pinned, vendored schemas. Explicit `Schemas` mappings take precedence.

Customize Rails database expectations when an application uses nonstandard environments or inherited keys:

```yaml
YAML/Rails/DatabaseEnvironmentConsistency:
  RequiredEnvironments:
    - development
    - test
    - staging
    - production
  RequiredKeys:
    - adapter
    - database
  AllowMergeKeys: true
```

## Known limitations

- No cop autocorrects YAML in 0.1.0. Rewriting YAML safely across comments, aliases, anchors, merge keys, and ordering semantics requires dedicated research.
- Schema validation never retrieves remote references implicitly. Use local, reviewed schemas.
- The schema registry currently autodetects only Docker Compose and GitHub Actions workflows.
- The Rails database cop analyzes YAML statically. ERB-looking content is preserved as scalar text and never executed.
- Ordering and grouping cops skip mappings with complex or merge keys when enforcing an order could misrepresent YAML semantics.
- Parsing follows the Psych behavior supplied by the active Ruby version; parser edge cases will be expanded through dogfooding and a dedicated torture suite.

## Development and verification

Run `bin/setup`, then `bin/ci`. Use `bin/rspec` and `bin/rubocop` with passthrough arguments for focused checks.

`bin/package` builds the gem and verifies that runtime configuration, vendored schemas, Ruby code, and RBS signatures are present. `bin/e2e` installs that artifact into an isolated gem home and proves RuboCop plugin discovery against a Rails-shaped fixture outside the repository load path.

See the [documentation index](docs/README.md) for architecture notes and the [release runbook](docs/releasing.md) for trusted-publishing setup and release verification.

## Project layout

- `lib/` contains the plugin, cops, and public API.
- `config/` contains default RuboCop configuration and pinned schemas.
- `sig/` contains public RBS contracts.
- `spec/` contains behavior, integration, and coverage checks.
- `docs/` contains architecture and release documentation.
- `bin/` contains repeatable development, package, and external-fixture commands.

## License

RuboCop YAML is available under the [MIT License](LICENSE).

Source: [github.com/scarver2/rubocop-yaml](https://github.com/scarver2/rubocop-yaml)

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
