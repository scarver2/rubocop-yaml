<!-- docs/README.md -->
# Documentation

- The parser layer owns safe YAML parsing and source locations.
- Cops own policy and native RuboCop offense presentation.
- Schema checks never retrieve remote resources implicitly.
- `YAML/Style/KeyOrdering` ignores unknown keys in configured mode and skips mappings containing merge or complex keys. It intentionally has no autocorrection so comments and YAML semantics remain untouched.

Development and testing instructions live in the project [README](../README.md). More focused documents will accompany the relevant features.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
