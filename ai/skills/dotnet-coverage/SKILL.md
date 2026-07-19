---
name: credfeto-dotnet-coverage
description: Collect .NET code coverage with Microsoft.Testing.Platform and generate per-assembly HTML reports with reportgenerator. Use when measuring test coverage, running coverage tasks, or producing coverage reports in a .NET repository. Covers test project identification, correct dotnet test invocation, and report generation rules.
---

# .NET Code Coverage Collection and Reporting

Testing uses **Microsoft.Testing.Platform** (MTP, not VSTest). To collect coverage, run **one unit test project at a time**: this gives a clear picture of how well each assembly is covered by its own tests.

## Identifying Test Projects (MANDATORY)

A project is a test project **only** if its assembly name ends with one of these suffixes:

| Suffix | Type |
| ------ | ---- |
| `.Tests` | Unit tests |
| `.Integration.Tests` | Integration tests |
| `.Benchmark.Tests` | Benchmarks |

Rules that must never be broken:

- **Never** use "contains 'Test'" in a project name as a heuristic; a project named `*.TestHarness`, `*.Tests.Mocks`, or `*.Tests.Common` is NOT a test project.
- **Never** run `dotnet test` or `dotnet run` on `*.Benchmark.Tests` projects; BenchmarkDotNet performs real measurements that take hours and spawn dozens of build processes. CI handles benchmarks.
- **Never** target a project with `dotnet test` if its csproj contains `<IsTestProject>false</IsTestProject>` or `<IsTestingPlatformApplication>false</IsTestingPlatformApplication>`.
- **Do not** rely on `OutputType` or the project SDK as a discriminator; with Microsoft.Testing.Platform, legitimate test projects also use `OutputType=Exe`, and some use `Microsoft.NET.Sdk.Web`.
- **Always** verify `IsTestingPlatformApplication` in the csproj: this is the property `dotnet test` in .NET 10 uses for discovery, not `IsTestProject`. The naming convention and `IsTestingPlatformApplication` are the only reliable signals.

Test support libraries (e.g. `*.Tests.Mocks`, `*.Tests.Common`) exist to be referenced by test projects. They are **not** test projects and must never be targeted for test runs.

## Which Projects to Run for Coverage

**Only run unit test projects (`<AssemblyName>.Tests`)**; exclude:

- `<AssemblyName>.Integration.Tests`: integration tests inflate coverage numbers and test external dependencies, not isolated units.
- `<AssemblyName>.Benchmark.Tests`: benchmarks are not functionality tests and must never be included in coverage runs.

## Collecting Coverage

Project form: target one test project directly (the `cd` step is required):

```bash
cd {solution-src-dir}
dotnet test {AssemblyName}.Tests/{AssemblyName}.Tests.csproj \
  -c Release \
  -p:SolutionDir={solution-src-dir}/ \
  -- --coverage --coverage-output-format cobertura \
     --coverage-output {repo-root}/coverage/{AssemblyName}.coverage.cobertura.xml
```

Critical rules:

- **`cd` to the solution `src/` directory first** and use a **relative** project path: absolute paths trigger the legacy VSTest bridge, which MTP 2.0+ rejects on .NET 10 SDK.
- **`--` separator is required**: coverage flags must be passed to the test host, not the `dotnet test` CLI. Passing `--coverage` before `--` conflicts with xunit's argument parsing.
- **`-c Release`**: always run coverage in Release mode.
- **`-p:SolutionDir=`**: must be an absolute path ending with `/` so `UnitTests.props` is found via `$(SolutionDir)`.
- **`--coverage-output`**: use an absolute path pointing into the repo's `/coverage/` directory (gitignored). Name the file `{AssemblyName}.coverage.cobertura.xml`.

`UnitTests.props` **must** contain the coverage extension package. If it is missing, stop and demand it is added:

```xml
<PackageReference Include="Microsoft.Testing.Extensions.CodeCoverage" Version="*" />
```

Do not install `coverlet.collector`, `coverlet.msbuild`, or any VSTest data collector; they do not work with Microsoft.Testing.Platform. Do not switch to `dotnet-coverage` or any wrapper tool. If coverage is still not collected, verify that `UnitTests.props` is imported by the test project and that `Microsoft.Testing.Extensions.CodeCoverage` is present.

## Generating Reports with reportgenerator

After collecting `.cobertura.xml` files, generate reports using `dotnet reportgenerator` (always via `dotnet`, never the raw binary).

**Always generate one report per assembly**: pass only that assembly's `.cobertura.xml` as input:

```bash
dotnet reportgenerator \
  -reports:{repo-root}/coverage/{AssemblyName}.coverage.cobertura.xml \
  -targetdir:{repo-root}/coverage/{AssemblyName} \
  -reporttypes:Html
```

**Do not pass multiple assemblies' `.cobertura.xml` files into a single `reportgenerator` run.** If assembly A references types from assembly B, running them together causes B's components to appear in A's coverage report, which falsely lowers A's measured coverage.

When a combined view is needed (e.g. a summary dashboard), run each assembly individually first, then produce one additional combined report as a separate step:

```bash
dotnet reportgenerator \
  -reports:"{repo-root}/coverage/*.coverage.cobertura.xml" \
  -targetdir:{repo-root}/coverage/combined \
  -reporttypes:Html
```

The per-assembly reports remain the authoritative measure of test quality for each project.

## Specific Coverage Rules (MANDATORY)

- If a source generator is used, it is because the source-generated version is **wanted**. Do not turn it off to reach 100% coverage. Source-generated code (classes decorated with `[GeneratedCode]`) should be excluded from coverage measurements; it is considered tested by the generator's author.
- For methods whose success path requires live infrastructure (database connections, network sockets, file handles), that path is genuinely unreachable in a unit-test environment. Do not suppress PH2140, add `[ExcludeFromCodeCoverage]`, or any `coverage.settings.xml` `<Functions>` exclusion for the gap. Accept the coverage gap and note it; do not block work on it. Prefer mocking the success path first: if the underlying type or interface can be substituted, write a test that exercises it via a mock or substitute. Only if the path is genuinely unreachable in a unit test **and** is not covered by an integration-test project, escalate by raising a GitHub issue labelled `AI-Work`, `Low`, and `Blocked` to track getting it covered by integration tests.

## Per-File Cadence for Coverage Tasks

1. Write tests until the file reaches target coverage.
2. Commit the test file; push immediately.
3. Update the tracking sub-issue to mark the file done.
4. Move to the next file.

For complex files, commit + push + update after each round; do not wait until fully complete.
