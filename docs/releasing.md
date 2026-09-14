<!-- docs/releasing.md -->
# Releasing RuboCop YAML

RuboCop YAML publishes from GitHub Actions with RubyGems trusted publishing. The release workflow accepts tags matching `v*`, verifies that the tag matches `RuboCop::Yaml::VERSION`, runs the complete project checks, installs the packaged gem into an isolated Rails-shaped fixture, and then invokes the official RubyGems release action.

## One-time trusted publisher setup

Create a pending trusted publisher in the RubyGems account that will own `rubocop-yaml`:

- Gem name: `rubocop-yaml`
- Repository owner: `scarver2`
- Repository name: `rubocop-yaml`
- Workflow filename: `release.yml`
- GitHub environment: `release`

The repository must also have a GitHub Actions environment named `release`. Configure required reviewers there when an explicit deployment approval is desired. No long-lived RubyGems API key belongs in GitHub secrets.

## Release checklist

1. Confirm the release commit is on `master` and the worktree is clean.
2. Confirm `CHANGELOG.md` has a dated entry matching the version.
3. Run `bin/ci` to execute specs, coverage, RuboCop, RBS validation, and package inspection.
4. Run `bin/e2e` to install the built gem in an isolated gem home and lint a Rails-shaped fixture.
5. Create and push the signed release tag, such as `v0.1.0`.
6. Approve the `release` environment deployment if protection rules require it.
7. Verify the GitHub Actions release job, the RubyGems version, and the generated GitHub release/tag page.

## Failure and rollback boundaries

Do not move or reuse a published version tag. If verification fails before publication, fix the release branch and create the tag only after the corrected commit reaches `master`. RubyGems releases are immutable; if a defective version is published, document the defect, release a new patch version, and yank only when leaving the version available would materially harm users.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
