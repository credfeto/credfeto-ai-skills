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
- git.instructions: mandatory rule requiring verbatim command output in PR/issue comments before any diagnosis when a git command fails
### Fixed
- on_new_pr.yml: inline composite action logic to fix local action path resolution failure under pull_request_target
- Corrected plan-approval description: board Approved status or comment-based fallback (no board) are the explicit approval signals; orchestrator never auto-removes Blocked
### Changed
- SDK - Updated DotNet SDK to 10.0.301
### Deprecated
### Removed
### Deployment Changes
<!--
Releases that have at least been deployed to staging, BUT NOT necessarily released to live.  Changes should be moved from [Unreleased] into here as they are merged into the appropriate release branch
-->
## [0.0.0] - Project created