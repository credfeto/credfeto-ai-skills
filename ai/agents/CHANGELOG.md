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
- Reconciled agent definitions with their sources: pre-existing bug reporting, draft and auto-merge handling for Code Fixer, Rebase Agent and CI Debugger, CI Debugger round counting, trusted commenter and CI check rules for Orchestrator, and CI Monitor rewritten
- Rebase Agent no longer runs the post-rebase pre-commit-check itself; the Orchestrator runs it after the agent returns
- Orchestrator agent now runs the Post-Rebase Check after the Rebase Agent returns and records environment/infrastructure blocks with the env-block marker
### Deprecated
### Removed
### Deployment Changes

<!--
Releases that have at least been deployed to staging, BUT NOT necessarily released to live.  Changes should be moved from [Unreleased] into here as they are merged into the appropriate release branch
-->

## [0.0.0] - Project created
