---
name: credfeto-dependency-selection
description: Choose secure, actively-maintained, managed dependencies over native or hand-rolled code, and resolve conflicting package versions safely during merges or rebases. Use whenever adding a new package dependency, encountering hand-rolled code that duplicates a library or standard-library feature, or resolving a version conflict in a dependency manifest.
---

# Dependency Selection and Version Conflicts

## Third-Party Packages Require Human Approval (MANDATORY)

Adding any package **not** published by `credfeto` or `funfair-tech` (i.e. not a `Credfeto.*`/`FunFair.*` package, or the equivalent recognised first-party namespace in another ecosystem) is prohibited without explicit human approval. This applies regardless of how small, trivial, or transitive the package seems, and regardless of how urgently it's needed. Exception: a package change that a pre-commit component tool's own output demands as the specific fix for its failure; see [Pre-Commit/Component-Tool-Mandated Package Changes](#pre-commitcomponent-tool-mandated-package-changes-mandatory) below.

Before requesting approval, carry out a full security review of the candidate package and version:

- **Provenance**: the source repository, publisher/maintainer identity, and that the registry listing genuinely matches the claimed upstream project (guard against typosquatting and dependency confusion).
- **Known vulnerabilities**: check the exact proposed version and its transitive dependencies for published advisories/CVEs.
- **Maintenance health**: last release date, responsiveness to reported security issues, whether the project is archived, deprecated, or effectively unmaintained.
- **Licence**: confirm it's compatible with this project.
- **Footprint**: what it pulls in transitively, and whether that's proportionate to the problem being solved.

Then present the human with, and wait for their explicit sign-off before touching any manifest, lockfile, or import:

1. Package name, proposed version, and links to its source repository and registry listing.
2. The findings of the security review above.
3. Why it's needed: what it does that the standard library, an already-owned Credfeto/FunFair package, or an existing dependency cannot.
4. Alternatives considered and why they were rejected.

If working from a GitHub issue or PR: post the review as a comment, add the `Blocked` label, and do not proceed until an explicit human approval comment exists and `Blocked` is removed. Otherwise, ask the human directly and wait for an unambiguous go-ahead (`approved` / `go ahead` / `looks good` / `lgtm`).

## Pre-Commit/Component-Tool-Mandated Package Changes (MANDATORY)

Pre-commit and its component tools are configured by humans, so a tool-reported error demanding a specific package change is itself a human-authorised instruction, not a discretionary choice. When a tool's own output pins down the exact remediation, adding a package reference, changing an existing reference's metadata or version, or removing one, apply the fix and proceed without pausing for a fresh approval round-trip, even when it introduces a package not previously referenced anywhere in the repo.

This does not remove the security review, only the wait:

- Still carry out the full security review above for any package this newly introduces to the repo.
- If the review finds a genuine blocker (a known vulnerability advisory, a provenance/typosquat mismatch, an incompatible licence, or a maintenance status so poor the package cannot be trusted), this exception does not apply: fall back to the full approval-and-wait process above, since the tool's output cannot have authorised a fix its own security review flags as unsafe.
- If the review finds no blocker: post the findings for visibility and proceed with the fix and the current work without waiting for sign-off. If working from a GitHub issue or PR, post them as a normal comment; do not add the `Blocked` label for this case. If not, share them with the human directly (e.g. in chat).

This exception applies only when the tool's output pins down the exact remediation with no choice among alternatives left to you (for example, several packages could resolve the same advisory, or the fix could be a version bump or a package swap): any such choice remains a discretionary package decision, and the full approval-and-wait process above still applies.

## Choosing Packages

- Use only secure package versions; check for known vulnerabilities before adding a dependency.
- In managed languages (.NET, JVM, Python), prefer managed libraries over native; only use native if it is the most actively maintained and stable option.
- Avoid deprecated or obsolete packages and language features; if unavoidable, add a comment explaining why and when it can be removed.
- Prefer the standard library; where insufficient, use well-known, actively-maintained third-party libraries.
- If you find hand-rolled code duplicating standard-library or trusted-third-party functionality, raise a GitHub issue; do not modify it inline.
- When looking up available packages, versions, or metadata, use the package sources actually configured on the system rather than assuming the public default registry; there may be a private feed, proxy, or mirror in use.

## Resolving Version Conflicts When Merging or Rebasing

When a merge or rebase produces conflicting versions of the same package, action, or runtime (both branches changed the version), resolve each conflicting entry individually; never take a whole file wholesale from one side.

This applies to every version-bearing file, including:

- Dependency manifests: `.csproj`, `Directory.Packages.props`, `packages.config`, `package.json`, `requirements.txt`
- GitHub Actions `uses:` version pins in workflows and composite actions
- Runtime and tool versions: .NET SDK (`global.json`), `dotnet-tools.json`, Node.js (`.nvmrc`, `engines`, `setup-node` versions), Python (`.python-version`, `setup-python` versions), and similar

Rules:

1. Take the **latest** of the candidate versions.
2. **Stable-over-pre-release exception**: if one candidate is a stable (release) version and the other is a pre-release (alpha/beta/rc/preview/dev build, etc.), take the stable candidate even if the pre-release has a nominally higher version number. Only take a pre-release if every candidate is a pre-release, in which case take the latest of them.
3. **Security exception**: if the latest candidate is known to be less secure than another candidate (e.g. it has a published security advisory that the other does not), take the most recent candidate that is not affected.
4. Never resolve by downgrading below every candidate, and never invent a version that appears on neither side.
5. Lock files (`package-lock.json` and similar): do not hand-merge; resolve the manifest first, then regenerate the lock file with the package manager.
6. After the merge or rebase completes, run the build and tests. If the chosen version broke the build (API changes, removed features), fix the breakage on the same branch as part of the merge work; do not downgrade to avoid the fix.

### No Confirmation Needed When the Algorithm Resolves the Conflict

Rules 1-5 above are a complete, deterministic algorithm: for every conflicting entry there is exactly one correct resolution (the latest candidate, the stable candidate, or the security-exception candidate). Apply it and continue; do not stop a merge or rebase to ask for confirmation on a conflict this algorithm resolves unambiguously, and do not post a PR/issue comment asking someone to confirm the choice.

Only stop and ask when a conflict genuinely falls outside the algorithm, for example:

- The same package is bumped to two different, unrelated versions on both sides and there is no clear "latest" (e.g. divergent major versions).
- A security trade-off with no candidate that is both latest and unaffected.
