# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!--
Please ADD ALL Changes to the UNRELEASED SECTION and not a specific release
-->

## [Unreleased]
### Security
- Pin GitHub Actions in reconcile-skills.yml to full commit SHAs to prevent supply-chain tampering via mutable tags (#8)
### Added
- New git-rebase skill (credfeto-git-rebase) covering when to rebase and the full version-conflict-resolution algorithm, extracted from git-rebasing.instructions.md, which no existing skill fully credited despite being duplicated and drifting independently across four other skills
- New docker-rootless-podman-systemd skill (credfeto-docker-rootless-podman-systemd) covering configuring and debugging rootless Podman run by an unprivileged system-level systemd service with no login session, extracted from docker-rootless-podman-systemd.instructions.md, which no existing skill covered
- New long-running-commands skill (credfeto-long-running-commands) covering unconditional backgrounding of build/test/commit commands, reliable poll strings, poll-loop deadlines, and diagnosing sandbox-caused false timeouts in benchmark tests, extracted from task-workflow.instructions.md, which no existing skill fully covered
- New agent-routing skill (credfeto-agent-routing) covering model-tier selection, no-self-repair for mechanical roles, the work-type to agent-sequence routing table, and research-pass invocation and escalation rules, extracted from task-workflow.instructions.md and agent-roles.instructions.md, which no existing skill covered
- New issue-plan-approval skill (credfeto-issue-plan-approval) covering the plan-then-approval gate required before starting work on an issue with no existing PR, including the Implementation Plan comment format and workflow-board update commands, extracted from agent-roles.instructions.md, which no existing skill covered
- New pr-review-loop skill (credfeto-pr-review-loop) covering the simplify, code-review, and security-review PR gate phases, the static-analyzer-wins conflict rule, and the environment-block marker convention, extracted from agent-roles.instructions.md, which no existing skill covered
- New coverage-ratchet skill (credfeto-coverage-ratchet) covering the whole-repo per-language coverage gate against a committed COVERAGE.md baseline on origin/main, its bootstrap and rebase-conflict rules, and the per-language extraction commands, extracted from coverage-ratchet.instructions.md, which no existing skill covered
- New python skill (credfeto-python) covering mandatory virtual environments, the Python 2 prohibition, and idiomatic/modular/testable code style, extracted from python.instructions.md, which no existing skill covered
- New learnings-capture skill (credfeto-learnings-capture) covering filing a human-readable credfeto/credfeto-notes issue alongside every memory-file update, extracted from learnings.instructions.md and learnings.examples.md, which no existing skill covered
- New code-reviewer-subagents skill (credfeto-code-reviewer-subagents) covering the six parallel review lenses (Reuse, Quality, Efficiency, Correctness, Security, Compliance), their false-positive-minimising critical instructions, and the fix/escalate iteration cap, extracted from agent-roles.instructions.md, which no existing skill covered beyond invoking it as an opaque step
- New repo-auditor skill (credfeto-repo-auditor) covering grouping a full repository's files and running the six Code Reviewer sub-agent lenses against each group to raise labelled audit issues rather than fixing directly, extracted from agent-roles.instructions.md, which no existing skill covered
- New ci-debugger skill (credfeto-ci-debugger) covering reading full CI failure logs, fixing code-related causes directly, and escalating environment/infrastructure causes with the machine-readable auto-clearing block marker, extracted from agent-roles.instructions.md, which no existing skill covered
- New dependency-updater skill (credfeto-dependency-updater) covering auto-merging safe Dependabot patch/minor bumps, flagging major bumps to a human, and fixing a bot PR's changelog entry when taking ownership breaks its changelog-check job, extracted from agent-roles.instructions.md and changelog.instructions.md, which no existing skill covered
- New code-cleanup-commits skill (credfeto-code-cleanup-commits) covering separate-commit rules for dead code removal, incidental file cleanup, and refactoring, extracted from code-quality.instructions.md, which no existing skill covered
- New dotnet-dead-framework-guards skill (credfeto-dotnet-dead-framework-guards) covering removal of now-dead #if OR_GREATER framework guards and pre-floor fallback source files once a project's targets are raised, extracted from dotnet.instructions.md, which no existing skill covered
- New dotnet-nuget-vulnerability-suppression skill (credfeto-dotnet-nuget-vulnerability-suppression) covering per-project, advisory-URL, reason-documented, issue-tracked suppression of NuGet audit advisories, extracted from dotnet.instructions.md, which no existing skill covered
- New dotnet-exception-generation skill (credfeto-dotnet-exception-generation) covering defining and converting .NET exception classes via the Credfeto.Exceptions.SourceGenerator analyzer instead of hand-written constructors, extracted from dotnet.instructions.md, which no existing skill covered
- New language-conventions skill (credfeto-language-conventions) covering UK English for prose, platform-convention code identifiers, and the no-em-dash punctuation rule, extracted from language.instructions.md, which was only partially covered via the git-commit skill's commit-message scope
- New code-style skill (credfeto-code-style) covering the no-XMLDoc/Javadoc comment rule, why-only inline comments, cyclomatic complexity and connascence limits, and the immutability preference, extracted from code-quality.instructions.md, which no existing skill covered
- New dotnet-coding-conventions skill (credfeto-dotnet-coding-conventions) covering .NET identifier naming, StringComparer usage, one-type-per-file organisation, records-over-classes, value-type guidance, DebuggerDisplay, and the never-modify-nuget.config rule, extracted from dotnet.instructions.md, which no existing skill covered
- New dotnet-nullable-and-warnings skill (credfeto-dotnet-nullable-and-warnings) covering the compiler-enforced nullable reference type contract with no defensive null guards, and the warnings-as-errors/no-suppression-without-permission rule, extracted from dotnet.instructions.md, which no existing skill covered
### Fixed
- All ai/skills SKILL.md files: removed pervasive em dash characters from prose and YAML descriptions, replacing them with commas, colons, semicolons, or separate sentences to comply with language.instructions.md's punctuation rule
- pre-work-healthcheck skill: added the missing stable-over-pre-release version-conflict exception and the bot-created-PR commit-author verification step, drawn from git-rebasing.instructions.md and task-workflow.instructions.md
- dotnet-coverage skill: corrected the infrastructure-dependent-success-path coverage rule to prefer mocking the success path first and escalate via a GitHub issue only when genuinely unreachable and uncovered by integration tests, matching code-quality.instructions.md
- docker skill: updated the base-image version-pinning rule to prefer digest pinning when the repo's Dependabot docker ecosystem is configured, falling back to tag pinning otherwise, matching docker.instructions.md
- git-commit skill: added the missing Never Truncate Test/Commit Commands rule and the Template Rule Escalation procedure from task-workflow.instructions.md and git.examples.md
- git-branch skill: added the missing stable-over-pre-release version-conflict exception, the no-confirmation-needed escalation boundary, and the Rebase Agent force-push and escalation rules from git-rebasing.instructions.md and agent-roles.instructions.md
- github-issue skill: restored the Implementation Plan comment template to the exact format required by agent-roles.instructions.md, and added the missing issue-tracking cadence, Comment Replies, and Prompt Traceability rules
- github-workflows skill: rewrote the Version Pinning section to reflect the current SHA-preferred, tag-fallback policy conditioned on the repo's Dependabot github-actions ecosystem, and added the matching SHA-vs-tag update distinction
- npm-packages skill: added the missing new-package human-approval gate and the version-conflict stable-over-pre-release exception and no-confirmation-needed escalation boundary
- dependency-selection skill: added the missing Third-Party Packages Require Human Approval section in full, plus the version-conflict stable-over-pre-release exception and no-confirmation-needed escalation boundary
- Skill installer script: removed an em dash from a log message to comply with language.instructions.md's punctuation rule
- dotnet-coverage skill: restored the missing 100% code coverage requirement, the SuppressMessage prohibition alongside ExcludeFromCodeCoverage, and the never-run-benchmarks-manually clause, matching code-quality.instructions.md and dotnet.instructions.md
- github-workflows skill: completed the truncated Node.js deprecation warning quote to include the Node 24 enforcement deadline, matching github-workflows.instructions.md
- npm-packages skill: restored the four required disclosure items for new-package approval and the Blocked-label workflow branch for issue/PR-sourced approvals, matching packages.instructions.md
- pre-work-healthcheck skill: restored the two missing version-conflict rules (never downgrade below every candidate; regenerate lock files rather than hand-merging) and the post-rebase build-fix sentence, matching git-rebasing.instructions.md
- git-commit skill: added the missing em dash prohibition for commit messages from language.instructions.md
- git-branch skill: corrected the no-confirmation-needed algorithm scope from Rules 1-6 to Rules 1-5, and restored the missing update-the-issue-before-resuming step, matching git-rebasing.instructions.md and task-workflow.instructions.md
- github-issue skill: restored the mandatory Use Plan Mode directive in the Ad-Hoc Prompt Intake procedure, matching task-workflow.instructions.md
- README and skills.instructions.md: corrected the documented install command from ./ai/skills/install.sh to ./ai/skills/install, matching the actual installer filename
- docker-rootless-podman-systemd skill: removed the addition of NoNewPrivileges=yes from the ProtectHome fix and restored the missing NoNewPrivileges=yes Breaks newuidmap/newgidmap on Every Reboot section, correcting a direct contradiction of docker-rootless-podman-systemd.instructions.md that would have reintroduced a reboot-only rootless-Podman failure
- changelog skill: removed the documentation-only and AI-instruction-file skip rules that no longer exist in changelog.instructions.md, and added the missing Dependabot and Other Bot PRs procedure for when a pushed commit invalidates a bot PR's Changelog Not Required label
- structured-logging skill: added the missing .NET Source-Generated Logging rules (LoggerMessage source generators, LoggingExtensions naming convention) from dotnet.instructions.md, now added as a second source
- pre-work-healthcheck skill: added the missing COVERAGE.md bootstrap-for-new-issues procedure and the coverage-baseline rebase-conflict handling from coverage-ratchet.instructions.md, now added as a source
- dotnet-coverage skill: updated the combined coverage report command to request the JsonSummary report type and extract the overall whole-repo line-coverage percentage with jq, matching the current dotnet.instructions.md guidance
- dotnet-owned-packages skill: corrected the Credfeto.Changelog.Cmd package registry row to the actual credfeto-changelog-manager GitHub repository slug, removing a stale misspelling note that dotnet-owned-packages.instructions.md itself had already corrected
- git-branch skill: added the missing Destructive Commands git-status-before-discarding-work rule and the Avoid git worktree rule from git.instructions.md
- git-rebase skill: restored the dropped instruction not to hand-merge a coverage-baseline file conflict during a rebase, matching git-rebasing.instructions.md
- pr-sync skill: added the missing PR creation flow, the Environment/Infrastructure Block Marker convention, and the Correcting a Prior Claim rule from agent-roles.instructions.md and task-workflow.instructions.md
- github-issue skill: added the missing mandatory Workflow Project Board addition step and the Correcting a Prior Claim rule from task-workflow.instructions.md
- agent-routing skill: restored the placeholder-changelog and correction-changelog steps, each with its own Committer and PR Submitter hand-off, that the work-type routing table had dropped from task-workflow.instructions.md
- issue-plan-approval skill: added the mandatory workflow-board read-back verification step and the never-substitute-the-Blocked-label rule from agent-roles.instructions.md
- pr-review-loop skill: reversed a direct contradiction of agent-roles.instructions.md that told Phase A to block the PR on simplify non-convergence, restored the missing Phase D AI Coverage ratchet phase, folded the changelog-correction step into every fix loop, and added the mandatory workflow-board read-back verification step, adding coverage-ratchet.instructions.md as a source
- git-commit skill: added the missing Committer-role rules (GPG-signed commits, git-CLI-only commit/push, no --no-verify, escalate to Orchestrator after 3 failed pre-commit-hook cycles) from agent-roles.instructions.md, now added as a source
- git-commit skill: removed the invented rule that git push must always run via run_in_background; task-workflow.instructions.md only mandates backgrounding for git commit/pre-commit, dotnet build, dotnet test, npm test, and bun test
- pr-sync skill: added the missing Human Comment Requests: Run First gate from agent-roles.instructions.md, which must run before CI Checks so ad-hoc issue-creation requests in PR/issue comments are never skipped
- pre-work-healthcheck skill: added the missing rule against creating a duplicate branch/PR for an issue already in progress, and the duplicate-pair resolution procedure, from task-workflow.instructions.md's Bot-Created PRs section
- pre-work-healthcheck skill: restored the dropped no-PR/issue-comment clause when a version conflict is resolved unambiguously by the deterministic algorithm, drawn from git-rebasing.instructions.md
- github-workflows skill: restored the dropped never-downgrade/never-invent-a-version rule in the Version Pinning section's merge-conflict guidance, drawn from git-rebasing.instructions.md
- dotnet-test-patterns skill: added the missing general async rule (prefer async over sync, never block on async operations, no synchronous wrappers) from code-quality.instructions.md's Asynchronous Code section
- agent-routing and issue-plan-approval skills: replaced a fabricated description of the Pre-Work Baseline Check's contents (prerequisites, pre-commit baseline, dotnet buildcheck) with a plain reference to the check, since neither skill's declared sources (task-workflow.instructions.md, agent-roles.instructions.md) define what that check contains
- npm-packages skill: removed an em dash character from the New Package Approval presentation checklist, which language.instructions.md's Punctuation rule prohibits in generated text
- Restored dropped rules and fixed content drift in several skills (dotnet-publish, dotnet-test-patterns, coverage-ratchet, changelog, long-running-commands, dependency-updater) that had lost concrete rule details from their source instruction files during regeneration.
- Fixed inconsistent frontmatter description wording in the pre-work-healthcheck and dotnet-coverage skills so the trigger description reads as a single, coherent statement.
- Removed MANDATORY markers from the secure-coding and error-handling skills that were not present in their source instruction files, and correctly backtick-quoted the em dash character reference in the git-commit skill.
- agent-routing skill: narrowed the infeasible-task escalation trigger back to a Coding Researcher Not possible result only, removing an invented broader any-role trigger not present in agent-roles.instructions.md
- dependency-updater skill: added the missing skip condition for repos that do not keep a changelog (e.g. template repos) when fixing a bot PR's broken changelog-check job, matching changelog.instructions.md's When to Skip rule
- code-cleanup-commits skill: removed an invented used-by-more-than-one-caller definition of shared code not present in code-quality.instructions.md
- secure-coding skill: restored the dropped pointers to a repository's own AI instructions for its project-specific secrets management approach and vulnerability-scanning tool, matching security.instructions.md
### Changed
- Skill registry: added git-rebase and docker-rootless-podman-systemd entries, and credited git-rebasing.instructions.md, code-quality.instructions.md, packages.instructions.md, and docker-rootless-podman-systemd.instructions.md as sources for the skills that draw content from them
- Skill registry: added long-running-commands, agent-routing, issue-plan-approval, and pr-review-loop entries crediting task-workflow.instructions.md and agent-roles.instructions.md as their sources
- Reconcile-skills workflow now syncs .ai-instructions and ai/global from cs-template before reconciling, and runs daily instead of weekly
- Skill registry: added git-rebasing.instructions.md as a source instruction file for the github-workflows skill, reflecting the version-conflict-resolution rule it inlines from that file
- Skill registry: disambiguated the changelog and dependency-updater skills' source citation from the bare changelog.instructions.md filename (which two different files share) to ai/global/changelog.instructions.md, the file whose repo-agnostic skip rule they actually implement; added dotnet.instructions.md as a source for the coverage-ratchet skill, which inlines its test-project-identification definition
- Added agent-roles.instructions.md to the coverage-ratchet skill's registry entry, reflecting the round-cap escalation rule it already draws from that file.
- pre-work-healthcheck skill: added the missing Rules Compliance for In-Flight Work check, requiring open branches and PRs to be re-evaluated whenever an instruction file changes, extracted from task-workflow.instructions.md
- git-rebase skill: added the missing CHANGELOG.md conflict-resolution rule (keep entries from both sides) from agent-roles.instructions.md's Rebase Agent section, and added that file as a registry source
- dotnet-coverage skill: added the missing Setting Up a Test Support Library MSBuild property requirements, extracted from dotnet.instructions.md, needed alongside the existing test-project identification rules
- Updated the ai/local/skills.instructions.md Skill Registry to add the four new skills and the git-rebase skill's additional agent-roles.instructions.md source
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