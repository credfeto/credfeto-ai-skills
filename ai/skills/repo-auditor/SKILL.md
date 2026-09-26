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
2. Process groups sequentially. For each group, apply IDE MCP code analysis to the group's files, then launch the six Code Reviewer sub-agent lenses (Reuse, Quality, Efficiency, Correctness, Security, Compliance) **in parallel** against that group's full file set, not just recently changed files.
3. Do **not** fix findings. For each group that has findings, raise one GitHub issue:
   - Title: `Audit: <group-name> - <brief summary>`
   - Body: all findings from all sub-agents for that group, organised by sub-agent.
   - Label: `audit`
4. Skip groups where every sub-agent reports `{"clean": true}`; do not raise an issue for a clean group.

## Sub-Agent Lenses

Each lens applies the same false-positive-minimising critical instructions and finding categories it would use reviewing a diff, just against the group's full file set instead of only newly changed lines. Each reports `{"clean": true}` or `{"clean": false, "findings": [{"file": "...", "line": ..., "issue": "...", "suggestion": "..."}]}`.

- **Reuse**: identify opportunities to reuse existing code instead of writing new code.
  - Only flag cases where an existing utility or helper clearly covers the same need without modification; prioritise reuse that eliminates duplication across multiple call sites; do NOT flag cases where the existing code would require modification to be reused, since that is a refactor, not reuse.
  - Categories: utilities, library functions, shared components, or extension points not being used where applicable.
- **Quality**: identify code quality issues.
  - Only flag clear violations, not stylistic preferences; prioritise issues that harm maintainability or introduce technical debt; do NOT report formatting or naming style issues, since those are enforced by linting tooling.
  - Categories: duplication, leaky single-responsibility violations, redundant mutable state, excessive complexity.
- **Efficiency**: identify inefficiencies.
  - Only flag issues with measurable impact, not micro-optimisations; prioritise hot paths, loops, and data access patterns; do NOT report theoretical inefficiencies in cold paths that are not performance-critical.
  - Categories: non-optimal algorithms, inappropriate data structures, redundant repeated work, unnecessary allocations.
- **Correctness**: identify logic errors.
  - Only flag cases where the logic provably does not match the intent of the change; prioritise errors that could cause incorrect results, data corruption, or silent failures; do NOT flag style or structural issues.
  - Categories: boundary conditions, incorrect conditionals, unhandled edge cases, logic mismatched to intent.
- **Security**: perform a security-focused review for high-confidence vulnerabilities with real exploitation potential.
  - Only flag issues where you are >80% confident of actual exploitability; prioritise vulnerabilities that could lead to unauthorised access, data breaches, or system compromise; do NOT report denial-of-service, rate-limiting issues, or hard-coded secrets/credentials, since dedicated non-agentic tooling already covers those.
  - Categories: input validation, authentication, crypto, and injection issues.
- **Compliance**: check that files comply with all applicable rules in the repo's own instruction files.
  - Only flag clear violations of explicit rules, not inferred or implied guidance; prioritise violations that would cause the files to fail review or break established conventions; do NOT re-report issues already in scope for the Reuse, Quality, Efficiency, Correctness, or Security lenses.
  - Categories: violations of global instruction-file rules; violations of local instruction-file rules (not already covered by global rules); local rules that duplicate or restate a global rule (flag these for removal); changes that weaken the repo's own lint/build quality gates; language/framework/documentation convention violations; a leftover `.deleteme.now` placeholder file left in the repository.
