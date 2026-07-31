---
name: credfeto-dotnet-exception-generation
description: Define .NET exception classes via the Credfeto.Exceptions.SourceGenerator analyzer instead of hand-writing constructors. Use whenever defining a new exception type in a .NET project, or when encountering an existing hand-written exception class (with manually written constructors) in a project this generator could apply to.
---

# .NET Exception Class Generation

Use `Credfeto.Exceptions.SourceGenerator` to define exception types; it generates all required constructors automatically. Never hand-write exception constructors when this generator is available.

## Adding a New Exception Type

1. Add the package to the project as an analyzer only, not a runtime dependency:

   ```xml
   <PackageReference Include="Credfeto.Exceptions.SourceGenerator" Version="0.0.1.30" PrivateAssets="All" ExcludeAssets="runtime" />
   ```

   Always use the **latest stable release**, not the version shown above.

2. Declare the exception as a `sealed partial class` with a `[Description]` attribute providing the default message:

   ```csharp
   [Description("Default message")]
   public sealed partial class MyException : Exception;
   ```

## Converting Existing Hand-Written Exceptions

Apply the same rule to any project that already defines exceptions with hand-written constructors:

1. Add the `Credfeto.Exceptions.SourceGenerator` package reference (as above) if not already present.
2. Convert each existing exception class to `partial` and remove its hand-written constructors, letting the generator supply them.
3. Add a `[Description]` attribute for the default message if one isn't already present.

## Source

`Credfeto.Exceptions.SourceGenerator` is an org-owned package: never decompile or reverse-engineer it. Read its source directly from its GitHub repository if you need to understand its behaviour.
