---
name: credfeto-dotnet-dead-framework-guards
description: Remove framework version guards and fallback source files that have become dead structure once every target framework in a .NET project file is on a floor version they were written to guard against. Use when a project's <TargetFramework>/<TargetFrameworks> is raised, or when auditing a .NET project for #if NETx_0_OR_GREATER guards, negated framework guards, or leftover pre-floor fallback files (e.g. a hand-written Regex fallback for a [GeneratedRegex] source generator).
---

# .NET Dead Framework-Version Guards

When every target framework listed in a project file is on or above a given floor version (e.g. .NET 9), conditional-compilation guards written to support older frameworks become dead structure.

## Removing Unconditionally-True Guards

`#if NET9_0_OR_GREATER`, `#if NET8_0_OR_GREATER`, `#if NET7_0_OR_GREATER`, `#if NET6_0_OR_GREATER`, and any earlier `OR_GREATER` variant are always true once the project's floor meets or exceeds that version:

- Remove the `#if` directive itself.
- Keep the guarded body.
- Delete the `#else` branch and its fallback implementation entirely.

## Removing Unconditionally-False Guards

The corresponding negated guards (`#if !NET9_0_OR_GREATER`, etc.) are always false under the same floor:

- Remove the entire block, including the body: none of it can ever execute.

## Removing Fallback-Only Source Files

Delete any source file that exists solely as a pre-floor-version fallback implementation, for example a file named `*.net6.cs` or `*SourceGenerated.net6.cs` containing a hand-written `new Regex(...)` fallback for the `[GeneratedRegex]` source generator.

## Verification

After removing the conditional blocks and fallback files, verify the project still builds and all tests still pass. Treat this as a separate commit from any feature or fix work.
