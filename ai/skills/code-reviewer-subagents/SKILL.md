---
name: credfeto-code-reviewer-subagents
description: Review a diff for merge-readiness by launching six parallel sub-agent lenses (Reuse, Quality, Efficiency, Correctness, Security, Compliance), each with its own false-positive-minimising critical instructions and finding categories, fixing real findings and escalating unresolved ones after a capped number of iterations. Use when acting as the Code Reviewer role, or whenever dispatched as one of its six sub-agents, to review newly changed code.
---

# Code Reviewer: Parallel Sub-Agent Review

## Orchestrating the Review

1. Run `git -C <dir> diff origin/main...HEAD` to get the scope of changed code.
2. Apply IDE MCP code analysis to the changed files (see the ide-mcp-code-analysis skill for the full best-effort and reporting procedure).
3. Launch all six sub-agents below **in parallel** against that diff.
4. Each sub-agent reports `{"clean": true}` or `{"clean": false, "findings": [{"file": "...", "line": ..., "issue": "...", "suggestion": "..."}]}`.
5. Fix real findings one construct at a time, because a task carries exactly one change: each fix, with its Pattern Sweep handed over as for Code Writer, is re-run through Code Tester and committed by Committer before the next construct is started; skip false positives. Never start another fix, or another lens iteration, while the working tree holds an uncommitted fix: before the next fix, confirm the previous one is committed (`git -C <dir> status --porcelain` is empty apart from known untracked files), because a tree holding several fixes cannot be committed one change at a time. If Committer cannot be invoked, stop after the first tested fix and hand back to the Orchestrator with that fix uncommitted and every remaining finding reported as unresolved. The outgoing report carries every sweep record and every pre-existing bug, incoming and own, unchanged.
6. If fixing a finding requires knowledge outside the instruction files, invoke Coding Researcher first; do not guess or fabricate. If Coding Researcher returns **Not possible**, leave the finding unresolved and escalate to the Orchestrator with the explanation.
7. Report `{"clean": true, "sweeps": [...], "preExistingBugs": [...]}` or `{"clean": false, "fixes": [...], "sweeps": [...], "preExistingBugs": [...]}`, where `sweeps` carries every sweep record and `preExistingBugs` lists each pre-existing bug reported but not fixed (file, line, description), incoming (from a Code Writer or Code Fixer hand-off) and own, because without its own field such a bug is either dropped or misread as a fix. Never suggest in the report that a tree holding more than one change be split by hunk or by file, because each change must reach Committer on its own. Cap at 5 iterations.
8. The 5-iteration cap is hard: after the fifth iteration make no further fix of any kind, tests-only included. Report every finding still open to the Orchestrator as unresolved; the Orchestrator adds each as a PR comment for human consideration.
9. Report a pre-existing bug found outside the current change's scope to the Orchestrator in `preExistingBugs` rather than fixing it.
10. Never start a long-running command while another long-running command you started is still running: wait for the first command's completion notification before starting the next.
11. When a hook blocks a command and no form of the same operation that the hook accepts exists, put the blocked command and the hook's message, both verbatim, in the report to the Orchestrator. Never ask the caller to run the command, and never work around the block, including by creating or editing a settings, permission or hook file. Pass any such report received in an incoming hand-off on unchanged.
12. In a .NET repository, run builds, tests, coverage and checks through the `build-dotnet` MCP tools whenever the server lists them, using the raw `dotnet` commands only for a task it lists no tool for, never running the same build or test both ways, and polling each job's `job_status` about every 30 to 60 seconds. A job started through an MCP tool counts as a long-running command for step 10.

### Posting a Finding on a PR

To start a new inline review comment on a file and line, use `cfwf pr review-comment --repo <owner/repo> --pr <number> --path <file> --line <n> [--start-line <n>] [--side RIGHT|LEFT] --body-file -` with the text on stdin as a HEREDOC (never escaped `\n` sequences). It reads the PR's head commit itself (never pass a commit SHA), prints the same `inline` and `url` lines as `cfwf pr reply`, and exits 1 with a clear message when the line is not part of the diff; post once and check `cfwf pr comments` before posting again.

To reply to an existing review comment thread, use `cfwf pr reply --repo <owner/repo> --pr <number> --comment-id <inline id> --body-file <file|->`, taking the `inline` id from `cfwf pr comments --repo <owner/repo> --pr <number>`.

Each sub-agent below reviews only the newly changed code in the diff. When dispatched as part of a full-repository audit rather than a PR review, the scope becomes the full file set for whatever group is being audited instead.

## Sub-Agent: Reuse

Identify opportunities to reuse existing code instead of writing new code.

**Critical instructions:**

1. Minimise false positives: only flag cases where an existing utility or helper clearly covers the same need without modification.
2. Focus on impact: prioritise reuse that eliminates duplication across multiple call sites.
3. Exclusions: do not flag cases where the existing code would require modification to be reused; that is a refactor, not reuse.

**Categories:** utilities (helper methods/functions already present being reimplemented), library functions (standard library or existing dependency features being reimplemented), shared components (duplicated domain logic that belongs in a shared layer), extension points (existing abstractions such as interfaces or base classes not being used where applicable).

## Sub-Agent: Quality

Identify code quality issues.

**Critical instructions:**

1. Minimise false positives: only flag clear violations, not stylistic preferences.
2. Focus on impact: prioritise issues that harm maintainability or introduce technical debt.
3. Exclusions: do not report formatting or naming style issues; those are enforced by linting tooling.

**Categories:** duplication (copy-paste code that should be extracted), responsibility (leaky abstractions or methods doing more than one thing, per the Single Responsibility Principle), state (redundant or unnecessary mutable state), complexity (overly nested logic or methods too long to reason about).

## Sub-Agent: Efficiency

Identify inefficiencies.

**Critical instructions:**

1. Minimise false positives: only flag issues with measurable impact, not micro-optimisations.
2. Focus on impact: prioritise hot paths, loops, and data access patterns.
3. Exclusions: do not report theoretical inefficiencies in cold paths that are not performance-critical.

**Categories:** algorithms (non-optimal algorithms where a better alternative exists and data size warrants it), data structures (inappropriate structures causing unnecessary overhead, e.g. linear search on a list where a set or dictionary fits), redundant work (repeated calculations or queries that could be cached or hoisted), memory (unnecessary allocations or large object graphs held longer than needed).

## Sub-Agent: Correctness

Identify logic errors.

**Critical instructions:**

1. Minimise false positives: only flag cases where the logic provably does not match the intent of the change.
2. Focus on impact: prioritise errors that could cause incorrect results, data corruption, or silent failures.
3. Exclusions: do not flag style or structural issues; focus solely on whether the code does what it is supposed to do.

**Categories:** boundary conditions (off-by-one errors, incorrect loop bounds, fencepost errors), conditionals (incorrect boolean logic, missing negation, wrong operator), edge cases (null/empty input, zero values, empty collections, missing default cases), business logic (code that does not match the intent described in the issue or PR).

## Sub-Agent: Security

Perform a security-focused review to identify high-confidence security vulnerabilities with real exploitation potential. Scope: security implications newly added by the change.

**Critical instructions:**

1. Minimise false positives: only flag issues where you are more than 80% confident of actual exploitability.
2. Focus on impact: prioritise vulnerabilities that could lead to unauthorised access, data breaches, or system compromise.
3. Exclusions: do not report denial-of-service vulnerabilities, rate limiting issues, or secrets/credentials committed in code (private keys, passwords, API keys); those are covered by dedicated non-agentic tooling.

**Categories:** input validation (SQL injection, command injection, path traversal, XSS), authentication (bypass logic, privilege escalation, JWT flaws), crypto (weak algorithms, improper key storage), injection (deserialisation, eval injection, XML parsing issues).

## Sub-Agent: Compliance

Check that files comply with all applicable rules in the repository's own AI instruction files.

**Critical instructions:**

1. Minimise false positives: only flag clear violations of explicit rules, not inferred or implied guidance.
2. Focus on impact: prioritise violations that would cause the files to fail review or break established conventions.
3. Exclusions: do not re-report issues already in scope for the Reuse, Quality, Efficiency, Correctness, or Security sub-agents above.

**Categories:** global rules (violations of the repo's global instruction files applicable to the changed file types), local rules (violations of the repo's local instruction files applicable to the changed file types, without re-reporting a violation already covered by a global rule), rule hygiene (local rules that duplicate or restate a rule already present globally; flag these for removal), rule breaking (files that change linting rules or build rules in a way that weakens the repo's quality gates), language/framework rules (e.g. dotnet, shell, SQL instruction compliance where those apply), documentation rules (README, CHANGELOG, and comment conventions), leftover placeholder (a `.deleteme.now` file still present in the diff).
