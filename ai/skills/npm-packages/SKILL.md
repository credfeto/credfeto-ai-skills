---
name: credfeto-npm-packages
description: Pin npm/JavaScript/TypeScript package versions exactly and resolve version conflicts safely. Use whenever adding, updating, or reviewing entries in package.json, or resolving package-lock.json conflicts during a merge or rebase.
---

# NPM Package Version Management

## New Package Approval (MANDATORY)

Adding any **new** npm package (an entry not already in `package.json`) requires explicit human approval after a full security review; this is not optional and applies regardless of how small or transitive the package seems. Before requesting approval, review:

- **Provenance**: the source repository and publisher identity, confirming the registry listing genuinely matches the claimed upstream project (guard against typosquatting).
- **Known vulnerabilities**: published advisories/CVEs for the exact proposed version and its transitive dependencies.
- **Maintenance health**: last release date, responsiveness to security issues, whether the project is archived or unmaintained.
- **Licence**: confirm it is compatible with the project.
- **Footprint**: what it pulls in transitively, and whether that is proportionate to the problem being solved.

Present the findings to the human and wait for explicit sign-off (`approved` / `go ahead` / `looks good` / `lgtm`) before touching `package.json`, the lock file, or adding any import that depends on the package.

## Fixed Package Versions (MANDATORY)

- Always use **exact (pinned) version numbers** in `package.json`, no `^` or `~` prefixes.
- New packages must be added with `npm install --save-exact` (or `npm install -E`) to avoid range specifiers.
- Dev dependencies must also use exact versions: `npm install --save-dev --save-exact`.
- Do not use `*`, `latest`, or any semver range expressions.
- Updates to existing packages must be **explicit and intentional**: specify the target version directly rather than relying on range resolution.
- When updating a package, update only that package (and its required peer dependencies); do not allow transitive upgrades to pull in unreviewed version changes.

## Resolving Version Conflicts During Merge or Rebase

When a merge or rebase produces conflicting versions of the same package in `package.json` (both branches changed the version):

1. Resolve each conflicting entry individually; never take a whole file wholesale from one side.
2. Take the **latest** of the candidate versions.
3. **Stable-over-pre-release exception**: if one candidate is a stable (release) version and the other is a pre-release (alpha/beta/rc/preview/dev build, etc.), take the stable candidate even if the pre-release has a nominally higher version number. Only take a pre-release if every candidate is a pre-release, in which case take the latest of them.
4. **Security exception**: if the latest candidate is known to be less secure than another candidate (e.g. it has a published security advisory that the other does not), take the most recent candidate that is not affected.
5. Never resolve by downgrading below every candidate, and never invent a version that appears on neither side.
6. Do not hand-merge `package-lock.json`; resolve `package.json` first, then regenerate the lock file by running `npm install`.
7. After the merge or rebase completes, run the build and tests. If the chosen version broke the build (API changes, removed features), fix the breakage on the same branch as part of the merge work; do not downgrade to avoid the fix.

### No Confirmation Needed When the Algorithm Resolves the Conflict

Rules 2-6 above are a complete, deterministic algorithm: for every conflicting entry there is exactly one correct resolution (the latest candidate, the stable candidate, or the security-exception candidate). Apply it and continue; do not stop a merge or rebase to ask for confirmation on a conflict this algorithm resolves unambiguously, and do not post a PR/issue comment asking someone to confirm the choice.

Only stop and ask when a conflict genuinely falls outside the algorithm, for example:

- The same package is bumped to two different, unrelated versions on both sides and there is no clear "latest" (e.g. divergent major versions).
- A security trade-off with no candidate that is both latest and unaffected.

Note: this escalation boundary is about resolving an existing version conflict, not about adding a new package; adding any new package always requires the human approval in [New Package Approval](#new-package-approval-mandatory) above regardless of how the algorithm resolves any unrelated conflict.
