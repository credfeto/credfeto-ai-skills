---
name: credfeto-npm-packages
description: Pin npm/JavaScript/TypeScript package versions exactly and resolve version conflicts safely. Use whenever adding, updating, or reviewing entries in package.json, or resolving package-lock.json conflicts during a merge or rebase.
---

# NPM Package Version Management

## New Package Approval (MANDATORY)

Adding any package **not** published by `credfeto` or `funfair-tech` (i.e. not a `Credfeto.*`/`FunFair.*` package, or the equivalent recognised first-party namespace in the npm ecosystem) is prohibited without explicit human approval after a full security review. This applies regardless of how small, trivial, or transitive the package seems, and regardless of how urgently it's needed. Exception: a package a pre-commit component tool's own output (e.g. `npm audit`) demands as the specific fix for its failure; see [Conflict Resolution](#conflict-resolution-pre-commitcomponent-tool-mandated-package-changes-mandatory) below. Before requesting approval, review:

- **Provenance**: the source repository and publisher/maintainer identity, confirming the registry listing genuinely matches the claimed upstream project (guard against typosquatting and dependency confusion).
- **Known vulnerabilities**: published advisories/CVEs for the exact proposed version and its transitive dependencies.
- **Maintenance health**: last release date, responsiveness to security issues, whether the project is archived or unmaintained.
- **Licence**: confirm it is compatible with the project.
- **Footprint**: what it pulls in transitively, and whether that is proportionate to the problem being solved.

Present the human with, and wait for their explicit sign-off before touching `package.json`, the lock file, or adding any import that depends on the package:

1. Package name, proposed version, and links to its source repository and registry listing.
2. The findings of the security review above.
3. Why it's needed: what it does that the standard library, an already-owned Credfeto/FunFair package, or an existing dependency cannot.
4. Alternatives considered and why they were rejected.

If working from a GitHub issue or PR, follow the Blocked Label workflow: post the review as a comment, add `Blocked`, and do not proceed until an explicit human approval comment exists and `Blocked` is removed. Otherwise, ask the human directly and wait for an unambiguous go-ahead (`approved` / `lgtm`).

## Conflict Resolution: Pre-Commit/Component-Tool-Mandated Package Changes (MANDATORY)

Pre-commit and its component tools are configured by humans, so a tool-reported error (e.g. from `npm audit`) demanding a specific package change is itself a human-authorised instruction, not a discretionary choice by the agent. When a tool's own output pins down the exact remediation, adding a package reference, changing an existing reference's metadata or version, or removing one, apply the fix and proceed without pausing for a fresh approval round-trip, even when it introduces a package not previously referenced anywhere in the repo.

This does not remove the security review, only the wait:

- Still carry out the full security review from [New Package Approval](#new-package-approval-mandatory) above for any package this newly introduces to the repo.
- If the review finds a genuine blocker (a known vulnerability advisory, a provenance/typosquat mismatch, an incompatible licence, or a maintenance status so poor the package cannot be trusted), this exception does not apply: fall back to the full approval-and-wait process above, since the tool's output cannot have authorised a fix its own security review flags as unsafe.
- If the review finds no blocker: post the findings for visibility and proceed with the fix and the current work without waiting for sign-off. If working from a GitHub issue or PR, post them as a normal comment; do not follow the Blocked Label workflow for this case. If not (no issue or PR), share them with the human directly (e.g. in chat).

This exception applies only when the tool's output pins down the exact remediation with no choice among alternatives left to the agent (for example, several packages could resolve the same advisory, or the fix could be a version bump or a package swap): any such choice remains a discretionary package decision, not a tool mandate, and the full approval-and-wait process above still applies.

## Registry Lookup

Before searching for, adding or updating a package, check which registry is actually configured: `npm config get registry`. Use that registry for lookups rather than assuming the public npm registry, since it may point at a private feed, proxy, or mirror.

## Running npm Commands (MANDATORY)

- Run every npm command as one plain command from the working directory. When `package-lock.json` is not at the repo root, add `--prefix <dir>`, where `<dir>` is the relative path inside the repo holding it (e.g. `src`).
- Run `npm ci` and `npm install` with the tool's `run_in_background`, then wait for them and read their output.
- Never add a `cd`, a `--prefix` outside the allowed directories, a redirect to a file (`> $TMPDIR/npm.log`), a `;`/`&&` chain, or a pipe (such as `| tail`): a `cd`, chain, redirect or pipe makes the permission allow list reject the call, and a `--prefix` outside the allowed directories is blocked by the `enforce-allowed-dirs` hook, while the plain form is allowed.

## Installing Dependencies (MANDATORY)

- This covers installing from an existing lockfile; regenerating or updating `package-lock.json` follows [Fixed Package Versions](#fixed-package-versions-mandatory).
- Install with exactly `npm ci --ignore-scripts`, plus `--prefix` where [Running npm Commands](#running-npm-commands-mandatory) requires it.
- Never install without `--ignore-scripts`, and never run `npm rebuild`: CI installs without scripts too, so builds must not depend on them.

## General Package Rules

- Use only secure package versions.
- Avoid deprecated or obsolete packages and language features; if unavoidable, add a comment explaining why and when it can be removed.
- Prefer the standard library; where insufficient, use well-known actively-maintained third-party libraries.
- If you find hand-rolled code duplicating standard-library or trusted-third-party functionality, raise a GitHub issue; do not modify it inline.

## Fixed Package Versions (MANDATORY)

- Always use **exact (pinned) version numbers** in `package.json`, no `^` or `~` prefixes.
- New packages must be added with `npm install --save-exact --ignore-scripts` (or `npm install -E --ignore-scripts`) to avoid range specifiers.
- Dev dependencies must also use exact versions: `npm install --save-dev --save-exact --ignore-scripts`.
- Regenerate `package-lock.json` with `npm install --package-lock-only --ignore-scripts`.
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
6. Do not hand-merge `package-lock.json`; resolve `package.json` first, then regenerate the lock file with the package manager.
7. After the merge or rebase completes, run the build and tests. If the chosen version broke the build (API changes, removed features), fix the breakage on the same branch as part of the merge work; do not downgrade to avoid the fix.

### No Confirmation Needed When the Algorithm Resolves the Conflict

Rules 2-6 above are a complete, deterministic algorithm: for every conflicting entry there is exactly one correct resolution (the latest candidate, the stable candidate, or the security-exception candidate). Apply it and continue; do not stop a merge or rebase to ask for confirmation on a conflict this algorithm resolves unambiguously, and do not post a PR/issue comment asking someone to confirm the choice.

Only stop and ask when a conflict genuinely falls outside the algorithm, for example:

- The same package is bumped to two different, unrelated versions on both sides and there is no clear "latest" (e.g. divergent major versions).
- A security trade-off with no candidate that is both latest and unaffected.
