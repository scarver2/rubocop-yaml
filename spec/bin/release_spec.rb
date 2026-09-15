# spec/bin/release_spec.rb
# frozen_string_literal: true

require "fileutils"
require "open3"
require "tmpdir"

require "spec_helper"

RSpec.describe "bin/release" do
  let(:release_script) { File.expand_path("../../bin/release", __dir__) }

  it "creates an exact-SHA annotated tag without a GPG secret key" do
    Dir.mktmpdir("rubocop-yaml-release-spec") do |workspace|
      repository = File.join(workspace, "repository")
      remote = File.join(workspace, "origin.git")
      gpg_home = File.join(workspace, "empty-gnupg")
      gate_log = File.join(workspace, "gates.log")
      prepare_repository(repository, remote, gpg_home)

      release_sha = git(repository, "rev-parse", "HEAD").strip
      stdout, stderr, status = Open3.capture3(
        { "GNUPGHOME" => gpg_home, "RELEASE_GATE_LOG" => gate_log },
        File.join(repository, "bin/release"), chdir: repository
      )

      expect(status).to be_success, stderr
      expect(stdout).to include("Released v0.2.0 from #{release_sha}")
      expect(File.readlines(gate_log, chomp: true)).to eq(%w[package ci e2e])
      expect(git(repository, "cat-file", "-t", "refs/tags/v0.2.0").strip).to eq("tag")
      expect(git(repository, "rev-parse", "v0.2.0^{commit}").strip).to eq(release_sha)
      remote_target = git(repository, "ls-remote", "--tags", "origin", "refs/tags/v0.2.0^{}")
      expect(remote_target).to include(release_sha)
    end
  end

  def prepare_repository(repository, remote, gpg_home)
    FileUtils.mkdir_p([File.join(repository, "bin"), gpg_home])
    FileUtils.cp(release_script, File.join(repository, "bin/release"))
    write_release_helpers(repository)
    File.write(File.join(repository, "CHANGELOG.md"), "## 0.2.0 - 2026-09-15\n")
    initialize_repository(repository, remote)
  end

  def initialize_repository(repository, remote)
    git(File.dirname(remote), "init", "--bare", remote)
    git(repository, "init", "--initial-branch=master")
    git(repository, "config", "user.name", "Release Spec")
    git(repository, "config", "user.email", "release@example.com")
    git(repository, "add", ".")
    git(repository, "-c", "commit.gpgsign=false", "commit", "-m", "release candidate")
    git(repository, "remote", "add", "origin", remote)
    git(repository, "push", "-u", "origin", "master")
  end

  def write_release_helpers(repository)
    write_library(repository)
    write_gates(repository)
  end

  def write_library(repository)
    File.write(File.join(repository, "bin/_lib.sh"), <<~SH)
      set -euo pipefail
      BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
      ROOT_DIR="$(cd "$BIN_DIR/.." && pwd)"
      cd "$ROOT_DIR"
      run_bundle() { printf '0.2.0'; }
    SH
  end

  def write_gates(repository)
    %w[package ci e2e].each do |gate|
      path = File.join(repository, "bin", gate)
      File.write(path, "#!/usr/bin/env bash\nprintf '%s\\n' '#{gate}' >> \"$RELEASE_GATE_LOG\"\n")
      FileUtils.chmod("u+x", path)
    end
  end

  def git(directory, *arguments)
    stdout, stderr, status = Open3.capture3("git", *arguments, chdir: directory)
    raise stderr unless status.success?

    stdout
  end
end
