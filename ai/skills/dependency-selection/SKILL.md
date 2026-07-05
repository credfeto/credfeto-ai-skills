---
name: credfeto-dependency-selection
description: Choose secure, actively-maintained, managed dependencies over native or hand-rolled code, and resolve conflicting package versions safely during merges or rebases. Use whenever adding a new package dependency, encountering hand-rolled code that duplicates a library or standard-library feature, or resolving a version conflict in a dependency manifest.
---

# Dependency Selection and Version Conflicts

## Choosing Packages

- Use only secure package versions — check for known vulnerabilities before adding a dependency.
- In managed languages (.NET, JVM, Python), prefer managed libraries over native; only use native if it is the most actively maintained and stable option.
- Avoid deprecated or obsolete packages and language features; if unavoidable, add a comment explaining why and when it can be removed.
- Prefer the standard library; where insufficient, use well-known, actively-maintained third-party libraries.
- If you find hand-rolled code duplicating standard-library or trusted-third-party functionality, raise a GitHub issue — do not modify it inline.

## Resolving Version Conflicts When Merging or Rebasing

When a merge or rebase produces conflicting versions of the same package, action, or runtime (both branches changed the version), resolve each conflicting entry individually — never take a whole file wholesale from one side.

This applies to every version-bearing file, including:

- Dependency manifests: `.csproj`, `Directory.Packages.props`, `packages.config`, `package.json`, `requirements.txt`
- GitHub Actions `uses:` version pins in workflows and composite actions
- Runtime and tool versions: .NET SDK (`global.json`), `dotnet-tools.json`, Node.js (`.nvmrc`, `engines`, `setup-node` versions), Python (`.python-version`, `setup-python` versions), and similar

Rules:

1. Take the **latest** of the candidate versions.
2. **Security exception**: if the latest candidate is known to be less secure than another candidate (e.g. it has a published security advisory that the other does not), take the most recent candidate that is not affected.
3. Never resolve by downgrading below every candidate, and never invent a version that appears on neither side.
4. Lock files (`package-lock.json` and similar): do not hand-merge — resolve the manifest first, then regenerate the lock file with the package manager.
5. After the merge or rebase completes, run the build and tests. If the chosen version broke the build (API changes, removed features), fix the breakage on the same branch as part of the merge work — do not downgrade to avoid the fix.
