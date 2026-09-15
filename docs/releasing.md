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

Run `bin/release --check` to exercise the complete local release preflight without creating a tag. Run `bin/release` only after that exact release commit has been reviewed and accepted on `master`.

The script enforces this order:

1. Require a clean `master` worktree exactly synchronized with `origin/master`.
2. Read and validate `RuboCop::Yaml::VERSION` and require a dated matching `CHANGELOG.md` entry.
3. Refuse to reuse an existing local or remote version tag.
4. Run `bin/package`, `bin/ci`, and `bin/e2e` in order.
5. Create a signed `v<VERSION>` tag on the exact verified commit and verify its target and signature.
6. Push only that tag, allowing the `Release` GitHub Actions workflow to publish through RubyGems trusted publishing and create the GitHub release.
7. Approve the `release` environment deployment if protection rules require it.
8. Verify the GitHub Actions release job, the RubyGems version, the generated GitHub release, and installation of the public gem.

`bin/release` never creates a RubyGems API key, changes the version, edits the changelog, moves an existing tag, or uploads a gem directly.

## Failure and rollback boundaries

Do not move or reuse a published version tag. If verification fails before publication, fix the release branch and create the tag only after the corrected commit reaches `master`. RubyGems releases are immutable; if a defective version is published, document the defect, release a new patch version, and yank only when leaving the version available would materially harm users.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
