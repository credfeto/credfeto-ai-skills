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
### Changed
- Skill registry: corrected source instruction file attributions for git-commit, pr-sync, github-issue, npm-packages, and performance-benchmarking to list every instruction file each skill actually draws content from, and added the new docker skill entry
### Deprecated
### Removed
### Deployment Changes
<!--
Releases that have at least been deployed to staging, BUT NOT necessarily released to live.  Changes should be moved from [Unreleased] into here as they are merged into the appropriate release branch
-->
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