---
name: credfeto-agent-routing
description: Route a piece of work to the correct sequence of agent roles in a multi-agent implementation and review pipeline, including where the changelog placeholder/correction split and its Committer/PR Submitter/CI Monitor steps sit in each sequence, choose the right model tier per role, avoid self-repair in mechanical roles, and invoke a research pass when implementation knowledge is missing. Use when deciding which agent(s) or passes should handle a new issue, PR change request, coverage task, documentation change, rebase, CI failure, or dependency update, or when a role lacks the knowledge to implement or fix something and needs to research it first.
---

# Agent Routing and Research Escalation

The Orchestrator determines the work type and routes it via the table below. It never implements directly.

## Model Selection

| Use full model | Use lesser model |
| --- | --- |
| Orchestrator, Code Writer, Code Reviewer, Code Reviewer: Reuse, Code Reviewer: Quality, Code Reviewer: Efficiency, Code Reviewer: Correctness, Code Reviewer: Security, Code Reviewer: Compliance, Repo Auditor, Code Fixer, Coding Researcher, CI Debugger, Dependency Updater | Code Tester, Committer, Changelog, Rebase Agent, PR Submitter, CI Monitor |

Roles that make open-ended judgement calls about code or findings use the full model, because a weaker judgement there produces wrong code or missed findings. Mechanical roles use the lesser model, because they follow a fixed, fully specified procedure, including fixed decision rules such as CI Monitor's, make no such judgement calls, and hand any failure on rather than diagnosing it.

## Failure Handling: No Self-Repair

Mechanical roles must not interpret or fix failures. When a check fails: capture the full output, stop immediately, and return the failure details verbatim to the calling role.

## Routing Rules

Every sequence below starts with the repo's Pre-Work Baseline Check. It is an implicit first step of every sequence, not merely a standalone rule, and must actually run before the first role in the row is invoked.

| Work type | Role sequence |
| --- | --- |
| New feature / bug fix / refactor | Pre-Work Baseline Check → Changelog (placeholder) → Committer → PR Submitter → Code Writer → Code Tester → Code Reviewer → Changelog (correction) → Committer → PR Submitter → CI Monitor |
| `CHANGES_REQUESTED` on an existing PR, a verbal/chat request for changes on an open PR, or a pre-existing bug the human has chosen to bring into an open PR's scope | Pre-Work Baseline Check → Code Fixer (respond to every comment) → Code Tester → Code Reviewer → Changelog (correction) → Committer → PR Submitter → CI Monitor |
| Coverage-only task | Pre-Work Baseline Check → Changelog (placeholder) → Committer → PR Submitter → Code Writer (tests only) → Code Tester → Code Reviewer → Changelog (correction) → Committer → PR Submitter → CI Monitor |
| Documentation-only | Pre-Work Baseline Check → Changelog (placeholder) → Committer → PR Submitter → Code Writer (docs only) → Changelog (correction) → Committer → PR Submitter → CI Monitor |
| Rebase requested | Pre-Work Baseline Check → Rebase Agent → PR Submitter → CI Monitor |
| CI failure (unknown cause) | Pre-Work Baseline Check → CI Debugger → CI Monitor |
| Dependabot / dependency update | Pre-Work Baseline Check → Dependency Updater |

An AI Review Loop fix runs the changes-requested row from Code Fixer (or Code Writer, when the step names it) onwards: Code Fixer (or Code Writer) → Code Tester → Changelog (correction) → Committer → PR Submitter → CI Monitor. It drops the Pre-Work Baseline Check, because that check already ran when work on the PR began, and Code Reviewer, because the loop's next phase or round reviews the change anyway. No new row, role or model-selection entry is needed, because every step is an existing role doing its usual job.

A row starting with `Changelog (placeholder)` assumes the work item takes a changelog entry at all. If the work item hits the repo's changelog skip condition (template repo), the row runs **unchanged**: Changelog still runs first and Committer/PR Submitter still open the PR from that single-file commit, but Changelog commits a `.deleteme.now` placeholder file at the repo root (a short delete-before-merge comment as its content) instead of a `CHANGELOG.md` stub entry. Code Writer removes `.deleteme.now` as part of its first real change set, for Committer to commit as usual, and the later `Changelog (correction)` step is a no-op for these items.

The trailing `→ CI Monitor` step runs only in some run modes: CI Monitor is dormant in unattended runs and active in an interactive session. The Orchestrator states the run mode when it hands over, because CI Monitor runs as a sub-agent and cannot tell the mode itself; a hand-off that states no mode means unattended. In the CI failure row it follows only a fix CI Debugger pushed or a check it re-ran, because an escalation goes to the Orchestrator and watching the unchanged failure would only hand it straight back to CI Debugger. When all required checks pass, CI Monitor returns control to the Orchestrator, which runs the AI Review Loop if the PR has an unreviewed commit, that is, its head differs from the one named in the loop's latest accepted `### AI Review Loop: reviewed` comment, or there is no such comment. Otherwise, if the PR is ready and has no auto-merge request, the Orchestrator enables auto-merge, because that confirmed all-pass is the result the loop's final phase waits for; in any other case it does nothing more. This is because unreviewed change must not merge. CI Monitor does not handle bot-authored dependency-update PRs, because Dependency Updater owns their CI and merge decision.

Standard loop pattern: Code Writer/Code Fixer loops up to 5 times with Code Tester; Code Reviewer loops up to 5 times, re-running both each round.

## Why Changelog and Committer Each Appear Twice

The Changelog role runs in two distinct modes, both of which hand off to Committer and then PR Submitter rather than committing or opening the PR itself. Neither mode commits or runs build/tests; those are Committer's and Code Tester's jobs respectively.

- **Placeholder** (first occurrence in a row): runs before Code Writer touches any code, so the branch/PR exists from the very start of work on the item. It adds a stub entry (best-guess type, message `TBD - to be finalized after review`), then hands off to Committer, which commits `CHANGELOG.md` alone, and PR Submitter, which opens the draft PR from that single-file commit.
- **Correction** (second occurrence in a row): replaces the placeholder (or a prior correction) once there is a real diff to describe, after Code Tester and Code Reviewer are satisfied in the initial development loop, never before. It also re-runs after any AI Review Loop phase (Simplify, Code Review, Security Review) that actually changed files, so the entry keeps matching the diff those phases produced. It reads `git diff origin/main...HEAD`, removes the previous entry, and adds the corrected one, then hands off to Committer (code and tests as one commit, `CHANGELOG.md` as a separate commit) and PR Submitter (updates the existing PR).

## Invoking Research When Knowledge Is Missing

Code Writer, Code Fixer, Code Reviewer, and CI Debugger may invoke Coding Researcher on demand at any point when the knowledge to implement or fix something is lacking (unfamiliar APIs, library behaviour, patterns found in public repositories, framework-specific idioms). This does not count toward the standard loop limits above, but each calling role may invoke Coding Researcher at most 3 times per work item.

- Before invoking, check the work item's issue/PR for an existing `### Coding Researcher` comment answering the same question and reuse it if found; reused findings do not count toward the cap.
- After Coding Researcher returns, the calling role records the question and outcome as a `### Coding Researcher` comment on the issue/PR so it can be reused later.
- On reaching the cap, or if Coding Researcher returns **Not possible**, the calling role stops and escalates to the Orchestrator rather than continuing the loop or guessing.

### The Research Role Itself

When acting as Coding Researcher:

- Research how to best implement or fix the specific task the calling role lacks sufficient knowledge for.
- Use available tools (web search, API docs, public repositories) to find authoritative, up-to-date guidance.
- Treat the repo's own instruction files and its pinned/locked dependency versions as authoritative. When web guidance targets a newer library version than the repo pins, research against the pinned version and call out any version-specific discrepancy in the report.
- Return one of two outcomes to the caller:
  - **Actionable guidance**: concrete steps, code patterns, relevant API signatures, and any important caveats the caller must know before implementing.
  - **Not possible**: a clear statement that the task cannot be achieved as requested, with a brief explanation of why and (if applicable) the closest viable alternative.
- Report findings in a self-contained, persistable form (the question researched plus the outcome) so the calling role can record them on the work item's issue/PR. You have no repo or issue/PR access; do not attempt to post comments or persist findings yourself.
- Do not write production code or tests; research and report only.
- Do not call other agents; return findings directly to the calling role.

## Escalation When a Task Is Infeasible

If a delegated role escalates a task as infeasible (Coding Researcher returning **Not possible**), the Orchestrator does not re-route it unchanged. It records the finding on the issue/PR and surfaces it to the user for a decision: re-scope, accept the suggested alternative, or drop.
