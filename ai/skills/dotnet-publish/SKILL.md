---
name: credfeto-dotnet-publish
description: Enable trimming and AOT publishing on .NET executable projects in the correct staged order. Use when working on a .NET project that produces a publishable executable (OutputType=Exe or WinExe), or when asked to enable PublishTrimmed, PublishAot, or fix IL2xxx/IL3xxx warnings.
---

# .NET Publishing: Trimming and AOT

When working on a .NET project that produces a publishable executable (`OutputType=Exe` or `OutputType=WinExe`), follow these steps **in order**.

## 1. Enable Trimming First

Add `<PublishTrimmed>true</PublishTrimmed>` to the project file and verify the project builds without trim warnings or errors.

- Fix all `IL2xxx` trim-analysis warnings before committing.
- Replace reflection-based patterns with source-generated equivalents — for example, replace `JsonSerializer` usage with a `JsonSerializerContext` annotated with `[JsonSerializable]`.
- Apply `[DynamicallyAccessedMembers]` only where reflection is genuinely unavoidable and cannot be replaced with a source generator.
- Do not suppress trim warnings — treat them as blocking, consistent with `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>`.

## 2. Enable AOT Only After Trimming Is Clean

Once `<PublishTrimmed>true</PublishTrimmed>` builds without warnings, replace it with `<PublishAot>true</PublishAot>` (AOT implies trimming; both properties do not need to be set simultaneously).

- Fix all `IL3xxx` AOT-compatibility warnings.
- Remove any runtime code generation: `Emit`, `DynamicMethod`, `Expression.Compile`, `CSharpCodeProvider`, etc.
- Verify that every third-party package used by the executable has AOT-compatible code paths. Check for `IsAotCompatible=true` in the package metadata or a corresponding `[RequiresUnreferencedCode]` annotation indicating the incompatibility.
- Do not suppress AOT warnings — treat them as blocking.

## 3. If Blocked by an Incompatible Third-Party Dependency

Raise a GitHub issue in the current repository describing the incompatibility (package name, version, and the specific warning or error), then **stop**. Do not work around the incompatibility by suppressing warnings or downgrading the property.

## General Warning Rules

- Every project must build with `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>`.
- Never use `#pragma warning disable <ID>`, `<NoWarn>`, `<WarningsNotAsErrors>`, or `[SuppressMessage]` without explicit written permission from the repo owner.
- If a warning fires, fix the root cause. If the fix is non-obvious, raise a GitHub issue rather than suppressing the warning.
