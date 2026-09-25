---
name: credfeto-code-cleanup-commits
description: Keep dead-code removal, incidental file cleanup, and pattern-sweep fixes in their own commits, separate from the feature or fix change, and sweep the whole repository for other occurrences of a fixed construct before moving on. Use whenever removing unreachable code, tidying up unrelated issues in a file already being edited (unused imports, stale comments, unreachable branches, inconsistent formatting, duplicated code, code-analysis warnings or suppressions), or after fixing a bug or accepting a finding from a simplify, code-review, or security-review pass, or a human PR review comment.
---

# Code Cleanup Commit Hygiene

Dead-code removal, incidental cleanup, and pattern-sweep fixes are never bundled into a feature or fix commit. Each has its own commit boundary and its own pass/fail gate.

## Dead Code

- Remove unreachable code rather than writing tests around it.
- Dead/unreachable code removal is a separate commit from test changes, made after running tests on the entire handler or app; one method or function per commit.
- Shared code removal is only done once the entire codebase has 100% coverage; each removal is its own commit.

## Incidental File Cleanup

- If a file already being edited for a feature or fix has issues unrelated to the current change (e.g. unused imports/usings, unreachable branches, inconsistent formatting, stale comments, duplicated code, code-analysis warnings, or suppressions of code-analysis warnings), clean them up so the file is the best it can be, while keeping to the project's existing standards rather than inventing new ones.
- Duplication is not limited to the file itself: if the file duplicates code found elsewhere in the repository, eliminate the duplication (e.g. extract to a shared location) as part of this cleanup.
- Resolve code-analysis warnings in the file, including pre-existing ones unrelated to the current change. Prefer removing an existing suppression by refactoring the underlying code over leaving the suppression in place. Do not add a new suppression as a way to close this out; adding one is prohibited without explicit written permission, so fix the root cause instead of suppressing, in any language.
- Commit this cleanup separately from the feature/fix change.
- If a file has multiple distinct fix types (e.g. unused imports and stale comments), fix and commit them one type at a time: each fix type is its own commit, per file.
- Tests must pass after every cleanup commit.

## Pattern Sweep (MANDATORY)

After fixing a bug, or accepting a finding from a simplify, code-review, or security-review pass, or a human PR review comment, search the entire repository for other occurrences of the same construct before moving on. A fix applied to one site while the same construct survives elsewhere is an incomplete fix.

- Search for the construct, not the symptom: the same API misuse, boundary condition, missing guard, duplicated helper, or insecure call. Use whatever search fits the construct (identifier, call shape, regular expression).
- Before fixing a round's findings, group them by construct; each group gets one fix commit and one sweep. One sweep, and one sweep commit, per construct, not per finding or per occurrence: when several findings report the same construct at different sites, one sweep covers them all. Skip the sweep if a commit already in the current pull request carries a `Construct:` line for the same construct and no later commit reintroduced it; a site a later review round deliberately reverted is not reintroduced.
- Sweep in the working tree before handing off for build/test verification, so one run covers both the fix and the sweep; then commit the fix first and the sweep second, in the same pull request. Anything a fix-touched file depends on is part of the fix, not the sweep; only one build is needed between the two commits so the fix commit stands on its own.
- Record, for whoever commits the change: a `Construct:` line naming the construct searched for, the finding or comment reference, and one line per file the sweep touched with why that site matches, each marked sweep-only or fix-touched (or `Swept: none` when nothing was found). Staging is by whole file: sweep-only files form the sweep commit; sweep hunks and covering tests in files the fix touches go into the fix commit and are listed in its body with the same rationale.
- A sweep commit changes only the matching sites and the tests that cover them. Files touched only by the sweep are exempt from Incidental File Cleanup above (a file the fix also touches follows it as normal); raise a GitHub issue for anything else noticed there.
- A sweep that would touch more than 25 files is not applied silently: post the site list on the pull request, add a `Blocked` label, and wait for a human decision on whether it belongs in this pull request or a follow-up issue.
- The sweep commit carries a `Construct:` line naming the construct and cites every fix commit SHA it derives from. When every hit is in a file the fix already touches, there is no separate sweep commit: the fix commit body carries the `Construct:` line and per-file rationale. If the sweep finds nothing, the fix commit body carries `Construct:` and `Swept: none`; no sweep commit or extra comment is needed.
- A sweep hit that the project's build-time static analyser stack already enforces differently is left as-is.
