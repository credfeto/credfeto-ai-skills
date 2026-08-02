---
name: credfeto-dotnet-nullable-and-warnings
description: Treat nullable reference type annotations as a compiler-enforced contract with no defensive null guards on non-nullable parameters, build every project with warnings as errors, and never suppress a warning without explicit written permission from the repo owner. Use whenever writing or reviewing .NET code that touches nullability, adds a null check, or encounters a build warning.
---

# .NET Nullable Reference Types and Warning Suppression

## Nullable Reference Types (MANDATORY)

`<Nullable>enable</Nullable>` is a project-wide requirement for all .NET code, and warnings are errors (see Warning Suppression below). Every caller of every member, public or otherwise, is therefore itself built under `#nullable enable`: a caller passing null into a non-nullable parameter is a compiler-reported bug at the call site, not a runtime condition the callee needs to defend against.

- Do not add `ArgumentNullException.ThrowIfNull(...)` or hand-written null guards for parameters typed as non-nullable reference types, on any member, public, internal, or private. Reaching that check at runtime means the compiler-enforced contract was already violated; fix the call site, do not add a defensive check for it.
- This does not relax input validation for untrusted external input (deserialised request bodies, query strings, file contents, env vars, message queue payloads): deserialisers, reflection, and non-nullable-aware callers outside the codebase can all still produce a runtime null despite a non-nullable annotation, so those boundaries keep validating in full.
- If a parameter's nullability is genuinely uncertain at the call site (deserialisation, an external API contract, a third-party library without nullable annotations), type it `T?` and handle the null explicitly, rather than declaring it non-nullable and adding a guard to compensate.
- Do not widen a type or member's visibility (`private`→`internal`, `internal`→`public`) solely to make a null-argument path testable. If the only reason to reach a member from a test is to pass `null` (typically via the null-forgiving operator `!`) against a non-nullable parameter, that call is not a real scenario any compiler-checked caller can produce, so there is nothing to test; removing the guard per this rule also removes the coverage obligation for that path.

## Warning Suppression and Errors

- Every project must build with `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>`.
- Never use `#pragma warning disable <ID>`, `<NoWarn>`, `<WarningsNotAsErrors>`, or `[SuppressMessage]` without **explicit written permission from the repo owner**. Exception: per-advisory NuGet audit suppressions, which are always allowed per-project without sign-off.
- If a warning fires, fix the root cause. If the fix is non-obvious, raise a GitHub issue rather than suppressing the warning.
- Test projects are **not** exempt from this rule; suppressing warnings in test code is equally prohibited without explicit permission.
- **Exception: project-specific local instruction files.** A project's own local AI instructions may explicitly document approved suppressions for that repository. Approval must be granted via a PR comment from the repo owner; the local instruction file alone is not sufficient to grant permission. When a repo owner approves a suppression via a PR comment, the local instruction file must be updated in that same PR to document: the specific warning ID, the affected class of code, and the reasoning for the exception. Once documented following an explicit PR comment approval, that entry satisfies the "explicit written permission from the repo owner" requirement for future suppressions of that warning ID in that class of code. Local instructions take precedence over this rule where they exist.
