---
name: credfeto-code-cleanup-commits
description: Split dead-code removal, incidental cleanup, and refactoring into their own separate commits, distinct from feature or fix changes. Use whenever removing unreachable/dead code, tidying up unrelated issues in a file already being edited (unused imports, stale comments, unreachable branches, inconsistent formatting), or refactoring code after tests pass.
---

# Code Cleanup Commit Hygiene

Dead-code removal, incidental cleanup, and refactoring are never bundled into a feature or fix commit. Each has its own commit boundary and its own pass/fail gate.

## Dead Code

- Remove unreachable code rather than writing tests around it.
- Dead/unreachable code removal is a separate commit from test changes, made after running tests on the entire handler or app that contains it.
- One method or function removal per commit.
- Shared code may only be removed once the entire codebase has 100% coverage; each removal is still its own commit.

## Refactoring

- Review code after writing and testing it to decide whether refactoring is needed.
- Refactoring is always a separate commit from feature/fix changes.
- Tests must pass after every refactoring commit.

## Incidental File Cleanup

- If a file already being edited for a feature or fix has unrelated issues (unused imports/usings, unreachable branches, inconsistent formatting, stale comments), clean them up so the file is the best it can be, while keeping to the project's existing standards rather than inventing new ones.
- Commit this cleanup separately from the feature/fix change.
- If a file has multiple distinct fix types (e.g. unused imports and stale comments), fix and commit them one type at a time: each fix type is its own commit, per file.
- Tests must pass after every cleanup commit.
