---
name: credfeto-dotnet-coverage
description: Collect .NET code coverage with Microsoft.Testing.Platform and generate per-assembly HTML reports with reportgenerator, covering test project identification, correct dotnet test invocation, and report generation rules. Use when measuring test coverage, running coverage tasks, or producing coverage reports in a .NET repository.
---

# .NET Code Coverage Collection and Reporting

Testing uses **Microsoft.Testing.Platform** (MTP, not VSTest). To collect coverage, run **one unit test project at a time**: this gives a clear picture of how well each assembly is covered by its own tests. 100% code coverage must be maintained.

## Use the `coverage` MCP Tool First (MANDATORY)

When a `build-dotnet` MCP server is connected and lists the `coverage` tool, collect coverage with it and read the figures from its `job_result`; the commands in the rest of this skill (`dotnet test ... -- --coverage` and `dotnet reportgenerator`) are the raw fallback for when it does not.

- Use the raw commands only when the server shows no `coverage` tool: the server is not connected, or it does not list that tool.
- A session that has no build-dotnet tools because its role is not granted them (the Orchestrator) is not this case: a missing tool there means delegate coverage to the role that has it (Code Tester), never run the raw coverage command yourself. The raw commands follow every rule in this skill.
- Never run the same coverage collection both ways. A job's `job_result` is the result: do not repeat the run with the raw command to confirm it, and do not run the raw command while an MCP job is running. An MCP job is a long-running command, and the server itself runs only one job at a time.
- Wait for a job by polling `job_status` at a steady pace. The `coverage` tool starts a job and returns its id at once. Call `job_status` once, then wait about 30 to 60 seconds between calls, judging the gap from the step the job reports and how long it has run. Never call `job_status` in a tight loop, and never wrap it in a shell wait loop. When the state is no longer running, read `job_result` and judge the job by its per-step exit codes, test counts and failing tests. A job is not a background shell command: do not wait for it with `cfwf task wait` or a completion notification.
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
- **Never** run `dotnet test` or `dotnet run` on `*.Benchmark.Tests` projects; BenchmarkDotNet performs real measurements that take hours and spawn dozens of build processes. CI handles benchmarks; never run them manually.
- **Never** target a project with `dotnet test` if its csproj contains `<IsTestProject>false</IsTestProject>` or `<IsTestingPlatformApplication>false</IsTestingPlatformApplication>`.
- **Do not** rely on `OutputType` or the project SDK as a discriminator; with Microsoft.Testing.Platform, legitimate test projects also use `OutputType=Exe`, and some use `Microsoft.NET.Sdk.Web`.
- **Always** verify `IsTestingPlatformApplication` in the csproj: this is the property `dotnet test` in .NET 10 uses for discovery, not `IsTestProject`. The naming convention and `IsTestingPlatformApplication` are the only reliable signals.

Test support libraries (e.g. `*.Tests.Mocks`, `*.Tests.Common`) exist to be referenced by test projects. They are **not** test projects and must never be targeted for test runs.

### Setting Up a Test Support Library (MANDATORY)

When a project is a test support library (provides mocks, helpers, or base types for test projects) but is **not** itself a test runner, it must have all four of these properties set explicitly:

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

### Running the Command (MANDATORY)

When using the raw fallback, always run this `dotnet test` coverage command with `run_in_background: true`; never run it in the foreground, regardless of how fast the run is expected to be, and never wrap it in a shell `timeout`.

- Wait for the harness's background-task completion notification and judge the command only by the exit code it reports: 0 is a pass and anything else is a failure. Never match text the command prints, never poll its output file, and never use the `Monitor` tool or a poll loop to wait for it. Reading the output once the notification has arrived, to find the cause of a failure, is fine.
- Run only one long-running command (such as `dotnet build` or `dotnet test`) at a time; wait for the first one's completion notification before starting the next.
- Time-box the command to 30 minutes. The main session enforces this deadline, by scheduling a wake-up for 30 minutes after starting the command and stopping it with `TaskStop` if it has not finished; a sub-agent never enforces it and never stops the command itself.
- A long stretch with no new output is normal and is not a hang.

### Coverage Extension Package

`UnitTests.props` **must** contain the coverage extension package. If it is missing, stop and demand it is added:

```xml
<PackageReference Include="Microsoft.Testing.Extensions.CodeCoverage" Version="*" />
```

Do not install `coverlet.collector`, `coverlet.msbuild`, or any VSTest data collector; they do not work with Microsoft.Testing.Platform. Do not switch to `dotnet-coverage` or any wrapper tool. If coverage is still not collected, verify that `UnitTests.props` is imported by the test project and that `Microsoft.Testing.Extensions.CodeCoverage` is present.

## Generating Reports with reportgenerator

After collecting `.cobertura.xml` files with the raw fallback, generate reports using `dotnet reportgenerator` (always via `dotnet`, never the raw binary). When the `coverage` MCP tool is listed, use its figures instead. Unlike the `dotnet test` coverage command above, `reportgenerator` may run in the foreground, but always with an explicit maximum timeout set on the tool call, never the tool's built-in default.

**Always generate one report per assembly**: pass only that assembly's `.cobertura.xml` as input:

```bash
dotnet reportgenerator \
  -reports:{repo-root}/coverage/{AssemblyName}.coverage.cobertura.xml \
  -targetdir:{repo-root}/coverage/{AssemblyName} \
  -reporttypes:Html
```

**Do not pass multiple assemblies' `.cobertura.xml` files into a single `reportgenerator` run.** If assembly A references types from assembly B, running them together causes B's components to appear in A's coverage report, which falsely lowers A's measured coverage.

When a combined view is needed (e.g. a summary dashboard, or a single whole-repo coverage percentage), run each assembly individually first, then produce one additional combined report as a separate step, requesting both report types together:

```bash
dotnet reportgenerator \
  -reports:"{repo-root}/coverage/*.coverage.cobertura.xml" \
  -targetdir:{repo-root}/coverage/combined \
  -reporttypes:"Html;JsonSummary"
```

This writes the `Html` dashboard alongside `{repo-root}/coverage/combined/Summary.json`; the overall whole-repo line-coverage percentage is its `summary.linecoverage` field:

```bash
jq '.summary.linecoverage' {repo-root}/coverage/combined/Summary.json
```

The per-assembly reports remain the authoritative measure of test quality for each project; the combined run is only ever used for the single whole-repo figure, never as a per-assembly quality signal. The same assembly A/B cross-contamination caveat applies equally here.

## Specific Coverage Rules (MANDATORY)

- 100% code coverage must be maintained.
- If a source generator is used, it is because the source-generated version is **wanted**. Do not turn it off to reach 100% coverage. Source-generated code (classes decorated with `[GeneratedCode]`) should be excluded from coverage measurements; it is considered tested by the generator's author.
- For methods whose success path requires live infrastructure (database connections, network sockets, file handles), that path is genuinely unreachable in a unit-test environment. Do not suppress PH2140, add `[ExcludeFromCodeCoverage]`, `[SuppressMessage]`, or any `coverage.settings.xml` `<Functions>` exclusion for the gap. Accept the coverage gap and note it; do not block work on it. Prefer mocking the success path first: if the underlying type or interface can be substituted, write a test that exercises it via a mock or substitute. Only if the path is genuinely unreachable in a unit test **and** is not covered by an integration-test project, escalate by raising a GitHub issue labelled `AI-Work`, `Low`, and `Blocked` to track getting it covered by integration tests.

## Per-File Cadence for Coverage Tasks

1. Write tests until the file reaches target coverage.
2. Commit the test file; push immediately.
3. Update the tracking sub-issue to mark the file done.
4. Move to the next file.

For complex files, commit + push + update after each round; do not wait until fully complete.
