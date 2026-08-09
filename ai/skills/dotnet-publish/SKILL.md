---
name: credfeto-dotnet-publish
description: Enable trimming and AOT publishing on .NET executable projects in the correct staged order. Use when working on a .NET project that produces a publishable executable (OutputType=Exe or WinExe), or when asked to enable PublishTrimmed, PublishAot, or fix IL2xxx/IL3xxx warnings.
---

# .NET Publishing: Trimming and AOT

When working on a .NET project that produces a publishable executable (`OutputType=Exe` or `OutputType=WinExe`), follow these steps **in order**.

## 1. Enable Trimming First

Add `<PublishTrimmed>true</PublishTrimmed>` to the project file and verify the project builds without trim warnings or errors.

- Fix all `IL2xxx` trim-analysis warnings before committing.
- Replace reflection-based patterns with source-generated equivalents: for example, replace `JsonSerializer` usage with a `JsonSerializerContext` annotated with `[JsonSerializable]`.
- Apply `[DynamicallyAccessedMembers]` only where reflection is genuinely unavoidable and cannot be replaced with a source generator.
- Do not suppress trim warnings; treat them as blocking, consistent with `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>`.

## 2. Enable AOT Only After Trimming Is Clean

Once `<PublishTrimmed>true</PublishTrimmed>` builds without warnings, replace it with `<PublishAot>true</PublishAot>` (AOT implies trimming; both properties do not need to be set simultaneously).

- Fix all `IL3xxx` AOT-compatibility warnings.
- Remove any runtime code generation: `Emit`, `DynamicMethod`, `Expression.Compile`, `CSharpCodeProvider`, etc.
- Verify that every third-party package used by the executable has AOT-compatible code paths. Check for `IsAotCompatible=true` in the package metadata or a corresponding `[RequiresUnreferencedCode]` annotation indicating the incompatibility.
- Do not suppress AOT warnings; treat them as blocking.

## 3. If Blocked by an Incompatible Third-Party Dependency

Raise a GitHub issue in the current repository describing the incompatibility (package name, version, and the specific warning or error), then **stop**. Do not work around the incompatibility by suppressing warnings or downgrading the property.

## General Warning Rules

- Every project must build with `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>`.
- Never use `#pragma warning disable <ID>`, `<NoWarn>`, `<WarningsNotAsErrors>`, or `[SuppressMessage]` without explicit written permission from the repo owner, except a per-advisory NuGet audit suppression (`<NuGetAuditSuppress>`), which is permitted without that sign-off but only per-project (never global), with the advisory URL and a `<!-- Reason -->` comment, and tracked in a GitHub issue.
- Test projects are not exempt from this rule; suppressing warnings in test code is equally prohibited without explicit permission.
- If a warning fires, fix the root cause. If the fix is non-obvious, raise a GitHub issue rather than suppressing the warning.
- **Exception: project-specific local instruction files.** A project's own local AI instructions may explicitly document approved suppressions for that repository. Approval must be granted via a PR comment from the repo owner; the local instruction file alone is not sufficient to grant permission. When a repo owner approves a suppression via a PR comment, the local instruction file must be updated in that same PR to document: the specific warning ID, the affected class of code, and the reasoning for the exception. Once documented following an explicit PR comment approval, that entry satisfies the "explicit written permission from the repo owner" requirement for future suppressions of that warning ID in that class of code. Local instructions take precedence over this rule where they exist.
