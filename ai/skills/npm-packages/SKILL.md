---
name: credfeto-npm-packages
description: Pin npm/JavaScript/TypeScript package versions exactly and resolve version conflicts safely. Use whenever adding, updating, or reviewing entries in package.json, or resolving package-lock.json conflicts during a merge or rebase.
---

# NPM Package Version Management

## Fixed Package Versions (MANDATORY)

- Always use **exact (pinned) version numbers** in `package.json` — no `^` or `~` prefixes.
- New packages must be added with `npm install --save-exact` (or `npm install -E`) to avoid range specifiers.
- Dev dependencies must also use exact versions: `npm install --save-dev --save-exact`.
- Do not use `*`, `latest`, or any semver range expressions.
- Updates to existing packages must be **explicit and intentional** — specify the target version directly rather than relying on range resolution.
- When updating a package, update only that package (and its required peer dependencies) — do not allow transitive upgrades to pull in unreviewed version changes.

## Resolving Version Conflicts During Merge or Rebase

When a merge or rebase produces conflicting versions of the same package in `package.json` (both branches changed the version):

1. Resolve each conflicting entry individually — never take a whole file wholesale from one side.
2. Take the **latest** of the candidate versions.
3. **Security exception**: if the latest candidate is known to be less secure than another candidate (e.g. it has a published security advisory that the other does not), take the most recent candidate that is not affected.
4. Never resolve by downgrading below every candidate, and never invent a version that appears on neither side.
5. Do not hand-merge `package-lock.json` — resolve `package.json` first, then regenerate the lock file by running `npm install`.
6. After the merge or rebase completes, run the build and tests. If the chosen version broke the build (API changes, removed features), fix the breakage on the same branch as part of the merge work — do not downgrade to avoid the fix.
