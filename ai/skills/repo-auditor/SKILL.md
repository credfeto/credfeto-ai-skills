---
name: credfeto-repo-auditor
description: Audit an entire repository (not a diff, no branch or PR required) by grouping its files, running the six Code Reviewer sub-agent lenses against the full file set of each group, and raising one labelled GitHub issue per group with findings instead of fixing anything directly. Use when asked to audit a whole repository, run a compliance sweep, or review the codebase as a whole rather than a specific change.
---

# Repository Audit

Scans the full repository rather than a diff; no branch or PR is required, and findings are reported as issues rather than fixed directly.

## Procedure (MANDATORY)

1. Group files for review before starting:
   - One group per project/app unit (e.g. one per `.csproj` or equivalent logical unit).
   - All SQL files as a single separate group, regardless of location.
   - All AI instruction files (the repo's own agent-facing rule files) as a single separate group.
   - Remaining files (shell scripts, CI workflow files, config) as a repo-level group.
2. Process groups sequentially. For each group, launch the six Code Reviewer sub-agent lenses (Reuse, Quality, Efficiency, Correctness, Security, Compliance) **in parallel** against that group's full file set, not just recently changed files.
3. Do **not** fix findings. For each group that has findings, raise one GitHub issue:
   - Title: `Audit: <group-name> - <brief summary>`
   - Body: all findings from all sub-agents for that group, organised by sub-agent.
   - Label: `audit`
4. Skip groups where every sub-agent reports `{"clean": true}`; do not raise an issue for a clean group.

## Sub-Agent Lenses

Each lens applies the same false-positive-minimising critical instructions and finding categories it would use reviewing a diff, just against the group's full file set instead of only newly changed lines:

- **Reuse**: existing utilities, library functions, shared components, or extension points not being used where applicable.
- **Quality**: duplication, leaky single-responsibility violations, redundant mutable state, excessive complexity.
- **Efficiency**: non-optimal algorithms, inappropriate data structures, redundant repeated work, unnecessary allocations.
- **Correctness**: boundary conditions, incorrect conditionals, unhandled edge cases, logic mismatched to intent.
- **Security**: high-confidence (>80% exploitability) input validation, authentication, crypto, and injection issues; excludes denial-of-service, rate limiting, and hard-coded secrets, which dedicated non-agentic tooling already covers.
- **Compliance**: violations of the repo's own global and local instruction files, rule-hygiene duplication between them, quality-gate-weakening changes to lint/build rules, and language/framework/documentation convention violations.
