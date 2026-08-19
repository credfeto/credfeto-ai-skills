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
- Add credfeto-code-tester skill, extracting the Code Tester agent role's build/test/coverage verification procedure from agent-roles.instructions.md, previously only named in routing tables
- Add credfeto-code-fixer skill, extracting the Code Fixer agent role's PR change-request procedure from agent-roles.instructions.md, previously only named in routing tables
- Register credfeto-code-tester and credfeto-code-fixer in the ai/local/skills.instructions.md skill registry
- New code-writer skill (credfeto-code-writer) covering the Code Writer agent role's implement-research-escalate-handoff procedure, extracted from agent-roles.instructions.md, which no existing skill covered despite every other named agent role having one
- code-fixer skill: added the exact gh api command for threading a reply onto an inline PR review comment (including the -F vs -f in_reply_to typing gotcha), and registered github-cli.instructions.md as a source
- Added the claude-hooks skill, generated from ai/global/claude-hooks.instructions.md, covering how to interpret a PreToolUse hook denial correctly
- New tool-preferences skill (credfeto-tool-preferences) covering when to reach for Glob over find for simple file listing, extracted from the new tool-preferences.instructions.md, which no existing skill covered
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
- dotnet-test-patterns skill: restored the missing (MANDATORY) marker on the Identifying Test Projects heading and fixed the matching anchor link, matching dotnet.instructions.md
- pr-sync skill: added the missing prohibition on running gh auth setup-git, which silently breaks git commit and push by rewriting the credential helper, matching github-cli.instructions.md
- dotnet-coding-conventions skill: added the missing Asynchronous Code and Cancellation section (ValueTask preference, CancellationToken propagation) that applies to all production code, not just tests, matching dotnet.instructions.md and code-quality.instructions.md
- agent-routing skill: removed an unsourced sentence from the No Self-Repair rule that was not present in task-workflow.instructions.md or agent-roles.instructions.md, so the skill no longer asserts guidance beyond what its sources actually say
- pr-review-loop skill: corrected two internal references to a non-existent step 2.5 in the coverage-ratchet decision procedure to the actual step 5, matching coverage-ratchet.instructions.md
- git-commit skill: added the missing Instruction File Source Routing rule (route ai/global changes to credfeto/cs-template, FunFair-specific changes to funfair-tech/funfair-server-template, otherwise commit locally), which task-workflow.instructions.md already required but no skill captured
- Fix coverage-ratchet skill to generate per-assembly coverage reports separately from the combined report, preventing cross-assembly contamination from producing false component-level coverage figures
- Fix docker-rootless-podman-systemd skill's ProtectHome=yes workaround to stop recommending PrivateTmp=yes, which orphans the rootless-Podman pause process against a deleted private /var/tmp and breaks later image pulls, and document the failure mode and recovery steps
- git-commit skill: restored the dropped 'stop and report the failure' clauses on the never-change-linting-rules and never-modify-ignore-files bullets, matching git-commits.instructions.md
- pr-sync skill: added the missing Authentication section (never gh auth login or manipulate credentials, unconditional gh auth setup-git refusal) and PR-side Prompt Traceability section, matching github-cli.instructions.md and task-workflow.instructions.md
- github-issue skill: added the missing Authentication section and removed an invented gh project item-add idempotency claim not present in any instruction file, matching github-cli.instructions.md
- pre-work-healthcheck skill: added the missing Pre-Commit Hook Known Incompatibilities section covering the dotenv-linter check subcommand requirement, matching git.instructions.md
- dotnet-coding-conventions skill: added the missing Time Abstraction section requiring System.TimeProvider over the obsolete ICurrentTimeSource/IDateTimeSource abstractions, matching dotnet.instructions.md
- git-commit skill: added the missing write-unit-tests-before-every-commit rule from code-quality.instructions.md, previously uncovered by any skill
- coverage-ratchet skill: restored the move-board-to-Human-Review instruction for non-code-only branches, the COVERAGE.md ownership and no-post-merge-job clause, the bootstrap recurrence explanation, the non-code-only safety-net paragraph, and the decision-procedure explanatory sentences, matching coverage-ratchet.instructions.md
- dotnet-publish skill: corrected the NuGet audit suppression exception to state its per-project, never-global, advisory-URL, and issue-tracking conditions instead of describing it as always permitted, matching dotnet.instructions.md
- dotnet-publish skill: restored the missing project-specific local instruction file exception to the warning-suppression rule, allowing a PR-comment-approved and locally documented suppression to satisfy the explicit-permission requirement, matching dotnet.instructions.md
- github-issue skill: restored the dropped 'no exception for credfeto/cs-template itself' clause on the Ad-Hoc Prompt Intake applicability rule, matching task-workflow.instructions.md
- coverage-ratchet skill: added the missing Whole-Repo Test-Infrastructure Exclusion section and fixed its dead self-anchor link, matching coverage-ratchet.instructions.md
- Update sql-schema-change skill's ad-hoc query guidance to route through the testdb/querydb wrapper instead of a direct sqlcmd invocation, matching the current sql.instructions.md source
- Add the missing bot-created-PR ownership check (app/github-actions commit-author verification and duplicate-PR handling) to the git-branch skill's pre-branch-creation check, matching task-workflow.instructions.md
- Corrected the new-package human-approval scope in the npm-packages skill so it matches packages.instructions.md (third-party only, not credfeto/funfair-tech-owned packages)
- Added the On-Hold label re-evaluation clause to the github-issue skill, matching agent-roles.instructions.md
- Added the PR-state verification step to the git-branch skill before treating an existing PR as a blocker, matching task-workflow.instructions.md's PR Lifecycle section
- Added the hook-denial-vs-killed-run distinction to the long-running-commands skill, reflecting the new claude-hooks.instructions.md cross-references in task-workflow.instructions.md
- Fixed a banned em dash character in the issue-plan-approval skill (credfeto-issue-plan-approval) to comply with the mandatory UK-English formatting rule that all generated skills must follow
- Correct the code-tester skill, which asserted an Orchestrator-escalation outcome for the 5-round Code Writer/Tester loop that the source instruction files never state
- pre-work-healthcheck skill: added a check for branches pushed but abandoned before a PR was opened, catching prior work the PR-only check misses
- git-branch skill: added a check for branches pushed but abandoned before a PR was opened, catching prior work the PR-only check misses
- git-commit skill: updated the Committer agent's placeholder-commit rule to cover the .deleteme.now convention used by template-skip repos, not CHANGELOG.md alone
- pr-review-loop skill: added the missing .deleteme.now placeholder safety-net check to the Mark Ready phase
- code-reviewer-subagents skill: added the missing leftover-placeholder (.deleteme.now) category to the Compliance sub-agent's checks
- coverage-ratchet skill: inlined the missing .NET dotnet test coverage-collection command so the skill is runnable without consulting another instruction file
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
- Regenerate credfeto-git-rebase skill to include the Rebase Agent role's build-break-escalation and non-algorithmic-conflict rules from agent-roles.instructions.md, which were missing
- Add the missing Setting Up a Test Support Library, Identifying Test Projects, Source Generator Test Projects, and Compile-Time Configuration testing rules to the credfeto-dotnet-test-patterns skill
- Add the all-projects-in-solution rule and the SolutionDir Directory.Build.props fallback fix to the credfeto-pre-work-healthcheck skill's .NET health check section
- Add the Orchestrator's CHANGES_REQUESTED-PR-over-new-issue selection priority to the credfeto-github-issue skill
- Regenerate the issue-plan-approval skill to add the missing rule that the approval gate applies only pre-PR and must never be re-derived from a PR's own workflow board card
- Add the inline PR review comment posting procedure to the code-reviewer-subagents skill, closing a gap where escalated findings had no documented gh api mechanism
- Correct the git-commit skill registry entry to list code-quality.instructions.md as a source, since its pre-commit test-writing rule is drawn from there
- coverage-ratchet skill: documented that the COVERAGE.md excluded marker now also applies to a whole-repo test-infrastructure language (with a one-line rationale), not just Shell, matching coverage-ratchet.instructions.md's new Whole-Repo Test-Infrastructure Exclusion rule
- pre-work-healthcheck skill: COVERAGE.md bootstrap step now documents that a whole-repo test-infrastructure language can also be recorded as excluded with a one-line rationale, not just Shell, matching coverage-ratchet.instructions.md's new rule
- code-fixer skill: added the HEREDOC-body rule for multi-paragraph gh pr comment replies, so a reply is never built with escaped \n sequences that GitHub renders as literal backslash-n text, matching github-cli.instructions.md's Comment and Body Text rule
- git-branch and git-rebase skills: corrected stale wording about coverage baseline rebase conflicts to match the current git-rebasing.instructions.md text, naming COVERAGE.md explicitly and describing it as generated content read live from origin/main
- Updated pre-work-healthcheck skill (credfeto-pre-work-healthcheck) to mandate backgrounding and waiting out the pre-commit baseline check rather than assuming automatic turn resumption, extracted from a new mandatory paragraph in git.instructions.md's Pre-Work Baseline Check section added after a confirmed live incident of the check being repeatedly abandoned across sessions
- Updated code-tester skill (credfeto-code-tester) to add the mandatory background/poll/30-minute-deadline procedure for running dotnet build and dotnet test, plus sandbox-caused false-timeout diagnosis for benchmark tests, which was missing despite task-workflow.instructions.md already being a listed source
- Correct the skill registry source-file lists for long-running-commands (add claude-hooks.instructions.md) and dependency-selection (drop the unused git.instructions.md) so each entry accurately reflects its skill's actual content
- pr-sync skill: cross-referenced the git-branch skill's abandoned-branch check, since the PR-based existing-work check alone does not catch it
- SDK - Updated DotNet SDK to 10.0.400
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