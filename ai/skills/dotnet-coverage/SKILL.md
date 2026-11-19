---
name: credfeto-dotnet-coverage
description: Collect .NET code coverage with the build-dotnet MCP server's coverage tool (Microsoft.Testing.Platform), covering test project identification, which projects are measured, the coverage extension package, and specific coverage rules. Use when measuring test coverage, running coverage tasks, or reading coverage figures in a .NET repository.
---

# .NET Code Coverage Collection

Coverage is collected with **Microsoft.Testing.Platform** (MTP). 100% code coverage must be maintained.

## Collect Coverage with the `coverage` MCP Tool (MANDATORY)

Collect coverage with the `coverage` tool of the `build-dotnet` MCP server and read the figures from its `job_result`. It measures one unit test project at a time with Microsoft.Testing.Platform's code coverage extension, writes each project's Cobertura file to `coverage/<AssemblyName>.coverage.cobertura.xml`, and reports per-assembly and Overall line coverage, so each assembly's figure comes from its own tests only.

The server runs the repository's .NET builds, tests, coverage and checks as jobs and keeps each job's full log. Its tool list follows the repository: it lists a tool only when the repository has something for it to run (for example `test` and `coverage` only when there is a unit test project).

- The raw commands the MCP tools replace (`dotnet test ... -- --coverage`, `dotnet reportgenerator`, `dotnet build`, `dotnet test`) are denied in the agent container, so a raw run is refused, never a fallback. `dotnet tool run` of `reportgenerator` is denied too. Never run `reportgenerator` as `dotnet reportgenerator`, `dotnet tool run reportgenerator` or a bare binary.
- A session that has no build-dotnet tools because its role is not granted them (the Orchestrator) hands the coverage task to the role that has them (Code Tester), because the raw commands are denied there too.
- When the server is not connected, stop and report it. If no build-dotnet tools are available in a role that is granted them, the server failed to start or connect: stop the task, comment on the issue or PR that the build-dotnet MCP server is not connected, and add `Blocked`. Never work around it with a raw command or a script that runs one, because a workaround hides the broken setup.
- A tool the server does not list has nothing to run. When the server is connected but does not list the `coverage` tool, the repository has nothing for it (for example no unit test project); say so in your report instead of composing a command.
- A job's `job_result` is the result. Do not repeat a coverage job to confirm it. An MCP job is a long-running command, and the server itself runs only one job at a time, so run only one long-running command at a time.
- Wait for a job with `job_result`, never by polling `job_status`. The `coverage` tool starts a job and returns its id at once. Call `job_result` with that id: it waits up to 240 seconds for the job to finish and then returns its outcome, sending progress while it waits. Call `job_result` again only while the `state` it returns is `running`. `job_status` is a single look at which step a job is on; never call it in a loop, and never put a shell wait or `sleep` around either call, because the server already does the waiting. Judge the job by `job_result`'s per-step exit codes, test counts and failing tests. A job is not a background shell command: do not wait for it with `cfwf task wait` or a completion notification.
- Before handing back, wait for every job you started to finish.

## Identifying Test Projects (MANDATORY)

A project is a test project **only** if its assembly name ends with one of these suffixes:

| Suffix | Type |
| ------ | ---- |
| `.Tests` | Unit tests |
| `.Integration.Tests` | Integration tests |
| `.Benchmark.Tests` | Benchmarks |

Rules that must never be broken:

- **Never** use "contains 'Test'" in a project name as a heuristic; a project named `*.TestHarness`, `*.Tests.Mocks`, or `*.Tests.Common` is NOT a test project.
- **Never** run the tests of a `*.Benchmark.Tests` project (never name one as the `test` tool's project) and never `dotnet run` one; BenchmarkDotNet performs real measurements that take hours and spawn dozens of build processes. CI handles benchmarks; never run them manually.
- **Never** name a project as a test target if its csproj contains `<IsTestProject>false</IsTestProject>` or `<IsTestingPlatformApplication>false</IsTestingPlatformApplication>`.
- **Do not** rely on `OutputType` or the project SDK as a discriminator; with Microsoft.Testing.Platform, legitimate test projects also use `OutputType=Exe`, and some test projects use `Microsoft.NET.Sdk.Web`.
- **Always** verify `IsTestingPlatformApplication` in the csproj: this is the property `dotnet test` in .NET 10 uses for discovery, not `IsTestProject`. The naming convention and `IsTestingPlatformApplication` are the only reliable signals.

Test support libraries (e.g. `*.Tests.Mocks`, `*.Tests.Common`) exist to be referenced by test projects. They are **not** test projects themselves and must never be targeted for test runs.

### Setting Up a Test Support Library (MANDATORY)

When a project is a test support library (provides mocks, helpers, or base types for test projects) but is **not** itself a test runner, it must have all four of the following properties set explicitly:

```xml
<IsTestProject>false</IsTestProject>
<IsTestingPlatformApplication>false</IsTestingPlatformApplication>
<UseMicrosoftTestingPlatformRunner>true</UseMicrosoftTestingPlatformRunner>
<TestingPlatformDotnetTestSupport>true</TestingPlatformDotnetTestSupport>
```

It must also import `UnitTests.props` (a temporary workaround required by `FunFair.BuildCheck`; drop it once `FunFair.BuildCheck` no longer requires the import):

```xml
<Import Project="$(SolutionDir)UnitTests.props" Condition="Exists('$(SolutionDir)UnitTests.props')" />
```

- `IsTestProject=false`: tells `FunFair.BuildCheck` this is not a test project; without it, buildcheck errors because a project referencing test packages that lacks this flag is expected to be a test runner.
- `IsTestingPlatformApplication=false`: overrides the implicit `true` set by `FunFair.Test.Common`, xunit, and similar packages; without it, `dotnet test` on .NET 10 attempts to run the project as an executable and fails because `OutputType=Library`.
- `UseMicrosoftTestingPlatformRunner=true`: required by `FunFair.BuildCheck` for any project that references test packages, even when `IsTestProject=false`.
- `TestingPlatformDotnetTestSupport=true`: required by `dotnet buildcheck` for any project that references test packages (e.g. `xunit.v3.extensibility.core`, `FunFair.Test.Common`), even when `IsTestProject=false`; without it, buildcheck reports `Should specify TestingPlatformDotnetTestSupport as true`.

These projects keep `OutputType=Library`.

## Which Projects Are Measured

**Only unit test projects (`<AssemblyName>.Tests`) are measured for coverage.** These are never measured:

- `<AssemblyName>.Integration.Tests`: integration tests inflate coverage numbers and test external dependencies, not isolated units.
- `<AssemblyName>.Benchmark.Tests`: benchmarks are not functionality tests and must never be included in coverage runs.

## Coverage Extension Package

`UnitTests.props` **must** contain the coverage extension package. If it is missing, stop and demand it is added:

```xml
<PackageReference Include="Microsoft.Testing.Extensions.CodeCoverage" Version="*" />
```

Do not install `coverlet.collector`, `coverlet.msbuild`, or any VSTest data collector; they do not work with Microsoft.Testing.Platform. Do not switch to `dotnet-coverage` or any wrapper tool. If coverage is still not collected, verify that `UnitTests.props` is imported by the test project and that `Microsoft.Testing.Extensions.CodeCoverage` is present.

## Specific Coverage Rules (MANDATORY)

- 100% code coverage must be maintained.
- If a source generator is used, it is because the source-generated version is **wanted**. Do not turn it off to reach 100% coverage. Source-generated code (classes decorated with `[GeneratedCode]`) should be excluded from coverage measurements; it is considered tested by the generator's author, not by us.
- For methods whose success path requires live infrastructure (database connections, network sockets, file handles), that path is only reachable when actual infrastructure is available, so it is unreachable in a unit-test environment. Do not suppress PH2140, add `[ExcludeFromCodeCoverage]`, `[SuppressMessage]`, or any `coverage.settings.xml` `<Functions>` exclusion for the gap. Accept the coverage gap and note it; do not block work on it. Prefer mocking the success path first: if the underlying type or interface can be substituted, write a test that exercises it. Only if the path is genuinely unreachable in a unit test **and** is not covered by an integration-test project, raise a GitHub issue labelled `AI-Work`, `Low`, and `Blocked` to track getting it covered by integration tests.

## Per-File Cadence for Coverage Tasks

1. Write tests until the file reaches target coverage.
2. Commit the test file; push immediately.
3. Update the sub-issue to mark the file done.
4. Move to the next file.

For complex files, commit + push + update after each round; do not wait until fully complete.
