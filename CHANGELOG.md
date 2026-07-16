# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!--
Please ADD ALL Changes to the UNRELEASED SECTION and not a specific release
-->

## [Unreleased]
### Security
### Added
### Fixed
### Changed
### Deprecated
### Removed
### Deployment Changes
<!--
Releases that have at least been deployed to staging, BUT NOT necessarily released to live.  Changes should be moved from [Unreleased] into here as they are merged into the appropriate release branch
-->
## [0.0.2] - 2026-07-16
### Added
- New AI skills generated from previously uncaptured instruction content: secure-coding, error-handling, structured-logging, api-http-tests, gitignore-management, dependency-selection — registered in the skill registry
- New docker skill (credfeto-docker) covering Docker/Podman runner detection, Dockerfile and Compose authoring conventions, and image security basics — extracted from docker.instructions.md, which no existing skill covered
### Fixed
- dotnet-owned-packages skill: corrected GitHub repository URLs for Credfeto.Changelog.Cmd and FunFair.Test.* (had drifted from the source registry), and added the missing FunFair.CodeAnalysis and FunFair.Test.Infrastructure entries
- pre-work-healthcheck skill: added the missing resume-branch fetch/check/rebase sequence, restored the auto-fix new-branch-and-issue separation, corrected the pre-commit invocation to the resolved hook binary, and fixed hooks-path resolution to check system/global/local scopes in order
- secure-coding and api-http-tests skills: removed rules invented beyond their source instruction files (a package-version-conflict sentence not in security.instructions.md, and a .http-file-freshness sentence not in api.instructions.md)
- dotnet-test-patterns skill: corrected FunFair.Test.Infrastructure guidance (it is a transitive dependency, not an explicit package reference), documented the MockBase<T> namespace migration, and added the missing parameterised-tests and test-quality rules from code-quality.instructions.md
- git-commit skill: removed a GPG/git-identity verification section with no basis in any current instruction file, and restored the documented amend-before-push exception to the never-amend rule
- git-branch skill: replaced unsourced rebase guidance with the actual Pre-Work Baseline Check fetch/check/rebase sequence from git.instructions.md
- pr-sync skill: added the missing mandatory rule to check branch names in all open PRs for the issue number before creating a new branch
- performance-benchmarking skill: added the missing FUNFAIR_TEST_BENCHMARK_BUILD_TIMEOUT_SECONDS environment variable guidance and the zero-or-explicit-byte-threshold qualifier for allocation assertions
- firewall-rules and shell-scripts skills: removed a shebang-requirement sentence and a parenthetical example not present in shell.firewall.instructions.md or shell-scripts.instructions.md
- pre-work-healthcheck skill: removed the unsourced claim that the pre-commit baseline check is skippable when .pre-commit-config.yaml is absent, which could wrongly let an agent skip a mandatory check
- dotnet-test-patterns skill: added the missing ValueTask-preference and CancellationToken-propagation rules from dotnet.instructions.md so test helpers and mocks follow the same async conventions as production code
- git-commit skill: restored the missing step to visit the repo's Dependabot page when handling vulnerability warnings, matching git.instructions.md
- git-branch skill: added the missing resuming-interrupted-work branch-decision procedure from task-workflow.instructions.md and the CHANGELOG-conflict-resolution rule from agent-roles.instructions.md's Rebase Agent role
- pr-sync skill: added the mandatory --repo/--head flags for gh pr create under GH_HOST proxy routing, and the Comment Replies, CI Checks, and Blocked Label procedures from agent-roles.instructions.md so every PR-interacting agent run follows them
- github-issue skill: added the missing Blocked Label procedure, the ad-hoc issue-from-comment creation rule, the priority-based issue-selection preference, the Dependency Security Issues label definitions, and the mandatory Implementation Plan comment template — all present in task-workflow.instructions.md, git.instructions.md, and agent-roles.instructions.md but missing from the skill
- performance-benchmarking skill: added the mandatory rule against running *.Benchmark.Tests projects manually via dotnet test or dotnet run, from dotnet.instructions.md
- deprecation-handling skill: narrowed its trigger and scope to test output only, matching code-quality.instructions.md's Deprecation Warnings During Tests rule, which does not cover build-time warnings
### Changed
- Skill registry: corrected source instruction file attributions for git-commit, pr-sync, github-issue, npm-packages, and performance-benchmarking to list every instruction file each skill actually draws content from, and added the new docker skill entry
- Skill registry: added agent-roles.instructions.md as a source instruction file for the git-branch, pr-sync, and github-issue skills, reflecting the Blocked Label, comment-reply, CI-check, and rebase-conflict procedures now drawn from it
- SDK - Updated DotNet SDK to 10.0.302

## [0.0.1] - 2026-07-02
### Added
- git.instructions: mandatory rule requiring verbatim command output in PR/issue comments before any diagnosis when a git command fails
- AI skills for Claude Code (pre-work-healthcheck, changelog, dotnet-coverage, dotnet-publish, git-commit, git-branch, pr-sync, github-issue) generated from the global instruction files, with an installer that installs them into ~/.claude/skills as credfeto-<skill>
- Local instruction defining how skills are generated from instruction files and kept up to date, including a skill registry
- Weekly reconcile-skills workflow: runs Claude Code every Sunday to reconcile all skills against the current instruction files and pushes the result to main
- New AI skills generated from previously uncaptured instruction content: github-workflows, shell-scripts, sql-schema-change, npm-packages, performance-benchmarking, firewall-rules, readme-documentation, dotnet-owned-packages, dotnet-test-patterns, deprecation-handling — registered in the skill registry
### Fixed
- on_new_pr.yml: inline composite action logic to fix local action path resolution failure under pull_request_target
- Corrected plan-approval description: board Approved status or comment-based fallback (no board) are the explicit approval signals; orchestrator never auto-removes Blocked
- reconcile-skills workflow now uses the local dotnet-install and dotnet-tool composite actions (local tool manifest instead of a global install that was not reliably on PATH) and validates CHANGELOG.md with the changelog tool via dotnet-tool-run on every run
- reconcile-skills workflow passes the nuget feed inputs to dotnet-install (matching pr-lint.yml) so the changelog tool can restore; previously the generated NuGet.Config had no sources and the tool install failed
- git-commit skill: embedded git identity check script now rejects the same hard-coded wrong identity as git.examples.md — the skill had drifted out of sync with its source
### Changed
- SDK - Updated DotNet SDK to 10.0.301
- Changelog policy for this repository: every change, including AI instruction and skill changes, now requires a changelog entry
- README rewritten to describe this repository (installable AI skills, installer, weekly reconciliation) instead of the cs-template boilerplate
- reconcile-skills workflow commits via git-auto-commit-action using SOURCE_PUSH_TOKEN for checkout and push instead of hand-rolled git steps with GITHUB_TOKEN

## [0.0.0] - Project created