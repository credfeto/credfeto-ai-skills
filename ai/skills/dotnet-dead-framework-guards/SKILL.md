---
name: credfeto-dotnet-dead-framework-guards
description: Remove framework version guards and fallback source files that have become dead structure once every target framework in a .NET project file is .NET 9 or later. Use when a project's <TargetFramework>/<TargetFrameworks> is raised to .NET 9 or later, or when auditing a .NET project for #if NETx_0_OR_GREATER guards, negated framework guards, or leftover pre-.NET 9 fallback files (e.g. a hand-written Regex fallback for a [GeneratedRegex] source generator).
---

# .NET Dead Framework-Version Guards

When all target frameworks listed in a project file are .NET 9 or later, framework version guards whose condition is unconditionally true become dead structure.

## Removing Unconditionally-True Guards

`#if NET9_0_OR_GREATER`, `#if NET8_0_OR_GREATER`, `#if NET7_0_OR_GREATER`, `#if NET6_0_OR_GREATER`, and any earlier `OR_GREATER` variant are always true:

- Remove the `#if` directive itself.
- Keep the guarded body.
- Delete the `#else` branch and its fallback implementation entirely.

## Removing Unconditionally-False Guards

The corresponding negated guards (`#if !NET9_0_OR_GREATER`, etc.) are always false:

- Remove the entire block, including the body: none of it can ever execute.

## Removing Fallback-Only Source Files

Delete any source file that exists solely as a pre-.NET 9 fallback implementation, for example a file named `*.net6.cs` or `*SourceGenerated.net6.cs` containing a `new Regex(...)` fallback for the `[GeneratedRegex]` source generator.

## Verification

After removing the conditional blocks, verify the project still builds and all tests still pass. Treat this as a separate commit from any feature or fix work.
