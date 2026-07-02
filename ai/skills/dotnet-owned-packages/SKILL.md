---
name: credfeto-dotnet-owned-packages
description: Identify org-owned Credfeto.* and FunFair.* NuGet packages and read their source from GitHub instead of decompiling. Use whenever a Credfeto.* or FunFair.* package is encountered in a .NET repository — while debugging, researching behaviour, or adding a new dependency.
---

# Owned .NET Packages

## Rule (MANDATORY)

**Never decompile or reverse-engineer source code for packages listed here.** These packages are owned by the same organisation. Read the source directly from the linked GitHub repository instead.

This applies regardless of how the package is referenced — as an analyzer (`PrivateAssets="All"`), a runtime dependency, or a dotnet tool.

## Package Registry

| NuGet Package | GitHub Repository | Notes |
| --- | --- | --- |
| `Credfeto.Database.Source.Generation` | [credfeto-database-source-generator](https://github.com/credfeto/credfeto-database-source-generator) | Source generator for database access |
| `Credfeto.Enum.Source.Generator` | [credfeto-enum-source-generation](https://github.com/credfeto/credfeto-enum-source-generation) | Source generator for enum helpers |
| `Credfeto.Exceptions.SourceGenerator` | [credfeto-exception-source-generator](https://github.com/credfeto/credfeto-exception-source-generator) | Source generator for exception constructors |
| `Credfeto.Changelog.Cmd` | [credfeto-changelog-cmd](https://github.com/credfeto/credfeto-changelog-cmd) | `dotnet changelog` CLI tool |
| `FunFair.Test.Common` | [funfair-test-common](https://github.com/funfair-tech/funfair-test-common) | Shared test base classes and helpers |
| `FunFair.Test.Source.Generator` | [funfair-test-source-generator](https://github.com/funfair-tech/funfair-test-source-generator) | Source generator for test projects |
| `FunFair.BuildCheck` | [funfair-build-check](https://github.com/funfair-tech/funfair-build-check) | `dotnet buildcheck` CLI tool |

## When a Package Is Not Listed

If a `Credfeto.*` or `FunFair.*` package is encountered that is **not** in the table above:

1. Add it to the table before proceeding — do not decompile it.
2. Ask the user for the correct GitHub repository URL if it is not already known.

## Using the Registry

When source is needed to understand behaviour (e.g. to fix a bug, write a test, or check an API surface), clone or browse the linked repository directly rather than using a decompiler.
