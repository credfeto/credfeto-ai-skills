---
name: credfeto-dotnet-exception-generation
description: Define .NET exception classes via the Credfeto.Exceptions.SourceGenerator analyzer instead of hand-writing constructors, and choose a project-defined exception over an ill-fitting framework one. Use whenever defining a new exception type or raising an exception in a .NET project, or when encountering an existing hand-written exception class (with manually written constructors) in a project this generator could apply to.
---

# .NET Exception Class Generation

Use `Credfeto.Exceptions.SourceGenerator` to define exception types; it generates all required constructors automatically. Never hand-write exception constructors when this generator is available.

## Adding a New Exception Type

1. Add the package to the project as an analyzer only, not a runtime dependency:

   ```xml
   <PackageReference Include="Credfeto.Exceptions.SourceGenerator" Version="0.0.1.30" PrivateAssets="All" ExcludeAssets="runtime" />
   ```

   Always use the **latest stable release** of `Credfeto.Exceptions.SourceGenerator`.

2. Declare the exception as a `sealed partial class` with a `[Description]` attribute providing the default message:

   ```csharp
   [Description("Default message")]
   public sealed partial class MyException : Exception;
   ```

## Converting Existing Hand-Written Exceptions

Apply the same rule to any project that already defines exceptions with hand-written constructors:

1. Add the `Credfeto.Exceptions.SourceGenerator` package reference (as above) if not already present.
2. Convert each existing hand-written exception class to `partial`; do not hand-write exception constructors, because the generator supplies them.

## Choosing the Exception to Throw

- When code raises an exception, throw a project-defined exception type generated with `Credfeto.Exceptions.SourceGenerator`, named for the specific failure (for example `DatabaseConfigurationIncompleteException`).
- Do not force a failure into a framework exception whose meaning does not match it (for example `InvalidOperationException`, `ArgumentException` or `Exception`).
- Throw a framework exception only where it genuinely matches the contract, for example `ArgumentNullException` or `ArgumentOutOfRangeException` for argument validation at a public API boundary, or `NotSupportedException` for an unsupported operation.
- Adding `Credfeto.Exceptions.SourceGenerator` to a project to follow this rule needs no separate package approval.
- Existing code that throws an ill-fitting framework exception need not be changed opportunistically, but code review flags any new code that does.

## Source

`Credfeto.Exceptions.SourceGenerator` is an org-owned package: never decompile or reverse-engineer it. Read its source directly from its GitHub repository, [credfeto-exception-source-generator](https://github.com/credfeto/credfeto-exception-source-generator), if you need to understand its behaviour.
