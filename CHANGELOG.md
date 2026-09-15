<!-- CHANGELOG.md -->
# Changelog

## Unreleased

## 0.2.0 - 2026-09-15

- Add a reusable, source-located project index for Rails I18n locale files.
- Add `YAML/Rails/I18nLocaleConsistency` for missing translation paths.
- Add `YAML/Rails/I18nInterpolationConsistency` using official ruby-i18n interpolation semantics.
- Add `YAML/Rails/I18nDuplicateTranslation` for cross-file collisions.
- Add opt-in `YAML/Rails/I18nOrphanTranslation` for target-only paths.
- Add locale-aware `YAML/Rails/I18nPluralizationContract` validation backed by ruby-i18n semantics.
- Add the `i18n` runtime dependency with support for versions 1.14 through 1.x.

## 0.1.0 - 2026-09-13

- Establish the RuboCop plugin foundation.
- Add standardized local development commands and CI.
- Add a safe YAML parser abstraction with immutable nodes and source locations.
- Add `YAML/Lint/InvalidSyntax`.
- Add `YAML/Lint/DuplicateKey`.
- Add opt-in `YAML/Style/KeyOrdering`.
- Add opt-in `YAML/Style/KeyGrouping`.
- Add opt-in local JSON Schema validation.
- Add deterministic Compose and GitHub Actions schema autodetection.
- Add Rails database environment consistency checks.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
