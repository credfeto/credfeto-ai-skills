---
name: credfeto-dotnet-dead-framework-guards
description: Remove framework version guards, MSBuild conditions, fallback source files and polyfills that have become dead structure because their outcome is identical for every target framework of a .NET project. Use when a project's target frameworks change, or when auditing a .NET project for #if NETx_0_OR_GREATER guards, negated framework guards, conditions on $(TargetFramework), runtime framework-version checks, leftover fallback files (e.g. a hand-written Regex fallback for a [GeneratedRegex] source generator) or polyfill package references.
---

# .NET Dead Framework-Version Guards

## Target Set and Supported Floor

A project's **target set** is every target framework it builds, judged per project rather than per repo, because each project compiles only for the frameworks it builds.

- Read the target set from the evaluated MSBuild properties (for example `dotnet msbuild <project> -getProperty:TargetFrameworks -getProperty:TargetFramework`), not only from the `<TargetFramework>`/`<TargetFrameworks>` element in the `.csproj`, so that frameworks set in `Directory.Build.props` or an imported `.props` file are included.
- Where a condition adds a framework only in some environments (such as only on Windows or only in CI), that framework is part of the target set.
- Because the evaluated properties reflect only the current host environment, also read every conditional `TargetFramework`/`TargetFrameworks` element in the project and in imported `.props`/`.targets` files, and take the union of all of them as the target set.

Any guard, condition, file or package whose outcome is identical for every framework in the target set is dead structure: it can never take its other path, so it only adds noise and untested branches. Collapse it to the single surviving path.

A guard whose outcome differs for any framework in the target set is live and stays unchanged, such as `NET8_0_OR_GREATER` in a project targeting `net6.0;net8.0`. The test applies across framework families too: in a project targeting `netstandard2.0;net8.0` or `net48;net8.0`, `NET8_0_OR_GREATER` is false for the `netstandard2.0` or `net48` build, so the guard and its fallback stay.

A project's **supported floor** is the lowest framework in its target set, and is defined only when every framework in the target set is .NET 5 or later. A project that also targets .NET Standard, .NET Framework or .NET Core 3.1 or earlier has no supported floor, so judge each guard against each framework in its target set individually rather than against a floor.

## Preprocessor Guards (`#if`, `#elif`, `#else`)

- A symbol defined for every framework in the target set, or the negation of a symbol defined for none of them, is always true: remove the directive, keep the body, and delete the `#else` branch and its fallback implementation.
  For example `NETx_0_OR_GREATER` with `x` at or below the floor, `NET` when every target is .NET 5 or later, `NETCOREAPP` when every target is .NET Core or later, and exact `NETx_0` when `netx.0` is the only framework in the target set (such as `NET8_0` in a project targeting only `net8.0`).
- A symbol defined for none of the frameworks in the target set, or the negation of a symbol defined for every one of them, is always false: remove the whole block including its body.
  For example `#if !NETx_0_OR_GREATER` with `x` at or below the floor, `NETx_0_OR_GREATER` with `x` above the highest framework in the target set (such as `NET10_0_OR_GREATER` in a project targeting only `net8.0`), exact `NETx_0` for any version not in the target set, whether below or above the floor (such as `NET7_0` in a project targeting `net6.0;net8.0`), `NETSTANDARD*` when the target set has no .NET Standard target, and `NETFRAMEWORK`/`NET4*` when the target set has no .NET Framework target.
- Collapse an `#if`/`#elif`/`#else` chain to the one branch that survives, without any directive around it.

## Fallback Source Files

- Delete source files that exist solely as fallback implementations for frameworks below the floor or not targeted (e.g. files named `*.net6.cs`, `*.netstandard2.0.cs` or `*SourceGenerated.net6.cs`, such as a hand-written `new Regex(...)` fallback for the `[GeneratedRegex]` source generator once the floor is .NET 7 or later).
- Remove any `<Compile Remove="..."/>`/`<Compile Include="..."/>` items that existed only to switch those files in or out.

## MSBuild Conditions

Applies to `.csproj`, `Directory.Build.props` and `Directory.Build.targets`.

- Apply the same always-true/always-false test to `Condition` attributes on `PropertyGroup`, `ItemGroup`, `PackageReference`, `Compile` and similar elements, including comparisons against `$(TargetFramework)` and `$([MSBuild]::IsTargetFrameworkCompatible(...))` calls. Unwrap an always-true condition (keep the element, drop the `Condition`); delete an element whose condition is always false.
- In a project whose evaluated `TargetFrameworks` property (`dotnet msbuild <project> -getProperty:TargetFrameworks`) is non-empty, however many frameworks it lists (a single `<TargetFrameworks>net8.0</TargetFrameworks>` counts), or a shared file imported by any such project, MSBuild also evaluates an outer (cross-targeting) build in which `$(TargetFramework)` is empty, and restore and pack run in that build, so judge a condition that reads `$(TargetFramework)` against that empty value as well as against every framework in the target set.
  Such a condition is always true only when it is also true with `$(TargetFramework)` empty: `$([MSBuild]::IsTargetFrameworkCompatible('$(TargetFramework)', 'net8.0'))` in a project targeting `net8.0;net9.0` is true for every framework in the target set but not in the outer build, so it stays, because unwrapping it would apply its items and properties to restore and pack as well and can change the package's dependency groups.
  A condition that exists only to exclude the outer build, such as `'$(TargetFramework)' != ''`, is live for the same reason and stays unchanged.
- A shared `Directory.Build.props`/`.targets` file, or any `.props`/`.targets` file imported explicitly, applies to every project that imports it, including projects outside its directory, so judge its conditions against the union of the target sets of all those projects, not just the one being edited.
  A condition in that file is dead only when its outcome is identical for every framework in that union, so `'$(TargetFramework)' == 'netstandard2.0'` stays live when one importing project targets `netstandard2.0` even though every other importing project targets `net8.0`.

## Runtime Framework-Version Checks

- Collapse a runtime version check to its surviving path only when the project has a supported floor and the check is a lower bound at or below that floor, because roll-forward lets an app run on any runtime at or above its target framework, so the floor fixes only that the runtime is at least the floor: for example `Environment.Version.Major >= 8`, or a version parsed from `RuntimeInformation.FrameworkDescription` compared the same way, is always true with a floor of .NET 8 or later.
- Leave equality and upper-bound checks (such as `Environment.Version.Major == 8` or `Environment.Version.Major < 9`), and lower bounds above the floor, in place: a newer runtime the app rolls forward to can change their outcome.
- Collapse `RuntimeFeature.IsSupported(...)` only for a feature constant that every runtime at or above the floor always reports as supported and that no publish option or runtime configuration can switch off, such as `RuntimeFeature.IsSupported(RuntimeFeature.DefaultImplementationsOfInterfaces)` with any supported floor.
- Leave dynamic-code, AOT and trimming checks (`RuntimeFeature.IsDynamicCodeSupported`, `RuntimeFeature.IsDynamicCodeCompiled`, and `IsSupported(...)` for any host-configurable feature) in place: they depend on how the app is published (NativeAOT, trimming or runtime configuration), not on the target framework.
- Leave every runtime version check in place in a project with no supported floor: a .NET Standard build runs on any runtime, including .NET Framework, so its target set gives no lower bound on the runtime.
- Leave operating-system checks (`OperatingSystem.Is*()`, `OperatingSystem.Is*VersionAtLeast(...)`) in place: they depend on the host operating system, not the target framework, so the floor does not fix their outcome.

## Polyfills

- Remove a pure polyfill package reference (e.g. `System.Memory`, `System.Buffers`, `Microsoft.Bcl.AsyncInterfaces`, `Microsoft.Bcl.HashCode` or `PolySharp`) only when every framework in the target set ships the API it provides in-box.
- Treat a package that also ships in-box with the framework (e.g. `System.Text.Json`, `System.Collections.Immutable` or `System.Diagnostics.DiagnosticSource`) as removable only when its referenced version is not higher than the in-box version of every framework in the target set, and keep it otherwise, whatever the reason it was added.
  Compare against the framework version with a zero patch (for example `8.0.0` for `net8.0`), the lowest in-box version any runtime for that framework supplies, because the installed runtime patch decides which in-box version the app loads, so a `System.Text.Json` `8.0.5` reference in a `net8.0` project stays.
- Keep any package reference that fails the restore comparison under Verification below, because a direct reference can pin a transitive dependency above a vulnerable or too-low version.
- Delete polyfill source files and attribute definitions (e.g. hand-written `IsExternalInit`, `RequiredMemberAttribute` or nullable-analysis attributes) under the same every-target test.

## Verification

- After removing a package reference, compare the `dotnet restore` warnings and the `dotnet list package --include-transitive` output before and after, and put the reference back if any new `NU1901` to `NU1904` warning appears or any resolved version changes (including the removed package itself coming back transitively at a lower version).
- After removing the dead structure, verify the project still builds and all tests still pass, and treat the removal as a separate commit from any feature or fix work.
