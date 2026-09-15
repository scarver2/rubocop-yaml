<!-- docs/i18n-architecture.md -->
# Rails I18n Analysis Architecture

Rails I18n analysis deliberately separates source structure from translation semantics.

Psych and `RuboCop::Yaml::Rails::I18n::LocaleIndex` own static source concerns: discovering locale files, preserving exact file, line, and column locations, retaining duplicate definitions, and exposing translation paths and raw values. The index never boots Rails, executes ERB, loads application configuration, or mutates process-wide I18n state.

The official [`ruby-i18n/i18n`](https://github.com/ruby-i18n/i18n) gem is the semantic authority where translation behavior matters, including interpolation conventions, reserved interpolation keys, locale conventions, and pluralization behavior. Cops should use isolated or pure `i18n` APIs where practical and must not replace the host process's `I18n.backend`, `I18n.locale`, or `I18n.load_path`.

Structural comparisons such as missing paths, cross-file duplicate definitions, and orphan paths remain index responsibilities. Semantic cops combine those source-aware entries with `i18n` behavior, then anchor RuboCop offenses to the original YAML locations.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
