---
name: credfeto-agent-routing
description: Route a piece of work to the correct sequence of agent roles in a multi-agent implementation and review pipeline, including where the changelog placeholder/correction split and its Committer/PR Submitter steps sit in each sequence, choose the right model tier per role, avoid self-repair in mechanical roles, and invoke a research pass when implementation knowledge is missing. Use when deciding which agent(s) or passes should handle a new issue, PR change request, coverage task, documentation change, rebase, CI failure, or dependency update, or when a role lacks the knowledge to implement or fix something and needs to research it first.
---

# Agent Routing and Research Escalation

## Model Selection

| Use full model | Use lesser model |
| --- | --- |
| Orchestrator, Code Writer, Code Reviewer, Code Fixer, Coding Researcher, CI Debugger, Dependency Updater | Code Tester, Committer, Changelog, Rebase Agent, PR Submitter, CI Monitor |

Roles that make judgement calls (writing code, reviewing it, researching unfamiliar territory, debugging CI, evaluating dependency updates) need the full model. Roles that mechanically execute a fixed procedure (running tests, committing, updating a changelog, rebasing, opening a PR, watching CI) do not.

## Failure Handling: No Self-Repair (MANDATORY)

Mechanical roles must not interpret or fix failures. When a check fails: capture the full output, stop immediately, and return the failure details verbatim to the calling role. Do not guess at a fix, retry with modified parameters, or silently work around the failure; escalate it.

## Routing Rules

Every sequence below starts with the repo's Pre-Work Baseline Check as step 0; it must actually run before the first role in the row is invoked, not be treated as an optional formality.

| Work type | Role sequence |
| --- | --- |
| New feature / bug fix / refactor | Pre-Work Baseline Check → Changelog (placeholder) → Committer → PR Submitter → Code Writer → Code Tester → Code Reviewer → Changelog (correction) → Committer → PR Submitter → CI Monitor |
| Changes requested on an existing PR, or a verbal/chat request for changes on an open PR | Pre-Work Baseline Check → Code Fixer (respond to every comment) → Code Tester → Code Reviewer → Changelog (correction) → Committer → PR Submitter → CI Monitor |
| Coverage-only task | Pre-Work Baseline Check → Changelog (placeholder) → Committer → PR Submitter → Code Writer (tests only) → Code Tester → Code Reviewer → Changelog (correction) → Committer → PR Submitter → CI Monitor |
| Documentation-only | Pre-Work Baseline Check → Changelog (placeholder) → Committer → PR Submitter → Code Writer (docs only) → Changelog (correction) → Committer → PR Submitter |
| Rebase requested | Pre-Work Baseline Check → Rebase Agent → PR Submitter |
| CI failure (unknown cause) | Pre-Work Baseline Check → CI Debugger |
| Dependency update (e.g. Dependabot) | Pre-Work Baseline Check → Dependency Updater |

A row starting with `Changelog (placeholder)` assumes the work item takes a changelog entry at all. If the work item hits the repo's changelog skip condition (e.g. a template repo that does not keep a changelog for AI-instruction-only changes), drop the leading `Changelog (placeholder) → Committer → PR Submitter` and start the row at its first `Code Writer` step instead; the PR then opens from that first real commit, and the `Changelog (correction)` step later in the row becomes a no-op.

Standard loop pattern: Code Writer/Code Fixer loop with Code Tester up to 5 rounds; Code Reviewer loops up to 5 rounds, re-running both roles each round.

## Why Changelog and Committer Each Appear Twice

The Changelog role runs in two distinct modes, both of which hand off to Committer and then PR Submitter rather than committing or opening the PR itself:

- **Placeholder** (first occurrence in a row): runs before Code Writer touches any code, so the branch/PR exists from the very start of work on the item. It adds a stub entry (best-guess type, message `TBD - to be finalized after review`), then hands off to Committer, which commits `CHANGELOG.md` alone, and PR Submitter, which opens the draft PR from that single-file commit.
- **Correction** (second occurrence in a row): replaces the placeholder (or a prior correction) once there is a real diff to describe, after Code Tester and Code Reviewer are satisfied. It also re-runs after any later AI Review Loop phase that changes files, so the entry keeps matching the diff those phases produced. It reads `git diff origin/main...HEAD`, removes the previous entry, and adds the corrected one, then hands off to Committer (code+tests as one commit, `CHANGELOG.md` as a separate commit) and PR Submitter (updates the existing PR).

Neither mode of Changelog commits, pushes, or runs build/tests itself; those are Committer's and Code Tester's jobs respectively.

## Invoking Research When Knowledge Is Missing

Code Writer, Code Fixer, Code Reviewer, and CI Debugger may invoke a research pass on demand at any point when the knowledge to implement or fix something is lacking (unfamiliar APIs, library behaviour, patterns found in public repositories, framework-specific idioms). This does not count toward the standard loop limits above, but each calling role may invoke research at most 3 times per work item.

- Before invoking, check the work item's issue/PR for an existing `### Coding Researcher` comment answering the same question and reuse it if found; reused findings do not count toward the cap.
- After the research pass returns, the calling role records the question and outcome as a `### Coding Researcher` comment on the issue/PR so it can be reused later.
- On reaching the cap, or if the research pass returns **Not possible**, the calling role stops and escalates rather than continuing the loop or guessing.

### The Research Role Itself

When acting as the research pass:

- Research how to best implement or fix the specific task the calling role lacks sufficient knowledge for.
- Use available tools (web search, API docs, public repositories) to find authoritative, up-to-date guidance.
- Treat the repo's own instruction files and its pinned/locked dependency versions as authoritative. When web guidance targets a newer library version than the repo pins, research against the pinned version and call out any version-specific discrepancy in the report.
- Return exactly one of two outcomes to the caller:
  - **Actionable guidance**: concrete steps, code patterns, relevant API signatures, and any important caveats the caller must know before implementing.
  - **Not possible**: a clear statement that the task cannot be achieved as requested, with a brief explanation of why and (if applicable) the closest viable alternative.
- Report findings in a self-contained, persistable form (the question researched plus the outcome) so the calling role can record them on the work item's issue/PR; the research role itself has no repo or issue/PR access and must not attempt to post comments or persist findings.
- Do not write production code or tests; research and report only.
- Do not call other agents or roles; return findings directly to the calling role.

## Escalation When a Task Is Infeasible

If a delegated role escalates a task as infeasible (a research pass returning **Not possible**, or any other role reporting it cannot proceed), do not re-route it unchanged and retry blindly. Record the finding on the issue/PR and surface it to the human for a decision: re-scope, accept the suggested alternative, or drop the task.
