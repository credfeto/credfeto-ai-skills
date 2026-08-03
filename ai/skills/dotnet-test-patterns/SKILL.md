---
name: credfeto-dotnet-test-patterns
description: Write .NET unit tests using FunFair.Test.Common/FunFair.Test.Infrastructure base classes, mocking helpers, date sources, and xunit assertion patterns instead of hand-rolled equivalents. Use whenever writing or reviewing a .NET unit test (a *.Tests project).
---

# .NET Unit Test Patterns

## Test Fixture Base Classes

Test fixture classes must derive from `FunFair.Test.Common.TestBase` or one of its derivatives:

| Test type | Base class |
| --------- | ---------- |
| General unit tests | `TestBase` |
| Dependency injection registration tests | `DependencyInjectionTestsBase` |
| Validator tests | `ComplexValidatorTestBase` |
| Simple validator tests | `ValidatorTestBase` |
| Comparable object type tests | `ComparableObjectTestBase` |
| Comparable value type tests | `ComparableValueTestBase` |
| Equatable object type tests | `EquatableObjectTestBase` |
| Equatable value type tests | `EquatableValueTestBase` |
| Integration tests | `IntegrationTestBase` |
| General unit tests where we want logging | `LoggingTestBase` |
| Value type JSON converters | `JsonConverterStructTestBase` |
| Object type JSON converters | `JsonConverterTestBase` |
| Unit tests where we want to write temp files to disk and have them cleaned up | `LoggingFolderCleanupTestBase` |
| Tests on model binders | `ModelBinderTestsBase` |

All test projects must:

- Reference the latest release of `FunFair.Test.Common`.
- Import the latest release of `FunFair.Test.Source.Generator`.
- Include `<Import Project="$(SolutionDir)UnitTests.props" Condition="Exists('$(SolutionDir)UnitTests.props')" />`.

### Setting Up a Test Support Library (MANDATORY)

When a project is a test support library (provides mocks, helpers, or base types for test projects, e.g. `*.Tests.Mocks`, `*.Tests.Common`) but is **not** itself a test runner, it must have all four of the following properties set explicitly:

```xml
<IsTestProject>false</IsTestProject>
<IsTestingPlatformApplication>false</IsTestingPlatformApplication>
<UseMicrosoftTestingPlatformRunner>true</UseMicrosoftTestingPlatformRunner>
<TestingPlatformDotnetTestSupport>true</TestingPlatformDotnetTestSupport>
```

It must also import `UnitTests.props`:

```xml
<Import Project="$(SolutionDir)UnitTests.props" Condition="Exists('$(SolutionDir)UnitTests.props')" />
```

- `IsTestProject=false`: tells the build-check tooling this is not a test project; without it, a project referencing test packages that lacks this flag is expected to be a test runner and buildcheck errors.
- `IsTestingPlatformApplication=false`: overrides the implicit `true` set by `FunFair.Test.Common`, xunit, and similar packages; without it, `dotnet test` on .NET 10 attempts to run the project as an executable and fails because `OutputType=Library`.
- `UseMicrosoftTestingPlatformRunner=true`: required by the build-check tooling for any project that references test packages, even when `IsTestProject=false`.
- `TestingPlatformDotnetTestSupport=true`: required for any project that references test packages (e.g. `xunit.v3.extensibility.core`, `FunFair.Test.Common`), even when `IsTestProject=false`; without it, buildcheck reports `Should specify TestingPlatformDotnetTestSupport as true`.

These projects keep `OutputType=Library`. Never target them with `dotnet test`; see [Identifying Test Projects](#identifying-test-projects) below.

### Identifying Test Projects

A project is a test project **only** if its assembly name ends with one of these suffixes:

| Suffix | Type |
| ------ | ---- |
| `.Tests` | Unit tests |
| `.Integration.Tests` | Integration tests |
| `.Benchmark.Tests` | Benchmarks |

- **Never** use "contains 'Test'" in a project name as a heuristic; a project named `*.TestHarness`, `*.Tests.Mocks`, or `*.Tests.Common` is NOT a test project.
- **Never** run `dotnet test` or `dotnet run` on `*.Benchmark.Tests` projects; BenchmarkDotNet performs real measurements that take hours and spawn dozens of build processes.
- **Never** target a project with `dotnet test` if its csproj contains `<IsTestProject>false</IsTestProject>` or `<IsTestingPlatformApplication>false</IsTestingPlatformApplication>`.
- **Do not** rely on `OutputType` or the project SDK as a discriminator; with Microsoft.Testing.Platform, legitimate test projects also use `OutputType=Exe`, and some test projects use `Microsoft.NET.Sdk.Web`.
- **Always** verify `IsTestingPlatformApplication` in the csproj: this is the property `dotnet test` in .NET 10 uses for discovery, not `IsTestProject`. The naming convention and `IsTestingPlatformApplication` are the only reliable signals.

### Source Generator Test Projects

When writing unit tests that directly reference a source generator project via `<ProjectReference>` on .NET 10+, add the following MSBuild target to the test project's `.csproj`:

```xml
<Target Name="RemoveGeneratorNuGetCompileDependencies"
        AfterTargets="ResolveProjectReferences"
        BeforeTargets="ResolveAssemblyReferences">
  <ItemGroup>
    <_ResolvedProjectReferencePaths Remove="@(_ResolvedProjectReferencePaths)"
        Condition="'%(_ResolvedProjectReferencePaths.NuGetPackageId)' != '' And '%(_ResolvedProjectReferencePaths.IncludeRuntimeDependency)' == 'false'" />
  </ItemGroup>
</Target>
```

This prevents the generator's Roslyn NuGet dependencies (e.g. `System.Collections.Immutable 9.0` exported via `GetDependencyTargetPaths`) from appearing alongside the .NET 10 in-box versions in the test project's reference list, which would cause CS1685 ("predefined type defined in multiple assemblies").

## Asynchronous Code and Cancellation

- Prefer async over sync wherever supported; never block on async operations (always await or use async continuations); propagate async through the call stack, with no synchronous wrappers around async operations.
- Prefer `ValueTask`/`ValueTask<T>` over `Task`/`Task<T>` for test helper and mock methods: this avoids heap allocations on synchronous-completion paths. Only use `Task`/`Task<T>` where `ValueTask` is unsupported or the method always completes asynchronously.
- All async methods, including test helpers, must accept and pass down a `CancellationToken`.
- Never create a new `CancellationToken` when one has been provided, unless combining with a timeout via `CancellationTokenSource.CreateLinkedTokenSource`.
- Prefer overloads that accept a `CancellationToken`.
- Do not pass `CancellationToken.None` without an explicit documented reason.

## NSubstitute and FunFair.Test.Common Patterns

| Instead of | Use |
| ---------- | --- |
| `Substitute.For<IMyInterface>()` | `GetSubstitute<IMyInterface>()` (static, no `this.`) |
| `Substitute.For<ILogger<MyClass>>()` | `this.GetTypedLogger<MyClass>()` (instance, requires `this.`) |

- Never call `Substitute.For<T>()` in classes deriving from `TestBase` or `DependencyInjectionTestsBase`.
- Remove unused `using NSubstitute;` after replacing all `Substitute.For<>()` calls.
- All instance method calls on `TestBase` (including `GetTypedLogger<T>()`, `GetSubstitute<T>()`, `CancellationToken()`, and custom helpers) require explicit `this.`; IDE0009 is enforced as an error. Static helpers (e.g. `GetSubstitute<T>()`) must remain `static` to avoid this requirement.

## DI Setup Test Patterns

Use `AddMockedService<T>()` in tests deriving from `DependencyInjectionTestsBase` instead of concrete inner classes or `Substitute.For<T>()`:

```csharp
// Correct
private static IServiceCollection Configure(IServiceCollection services)
{
    return services.AddMyModule()
                   .AddMockedService<IFoo>()
                   .AddMockedService<IBar>();
}
```

Registering mocked `IOptions<T>`:

```csharp
// Correct
.AddMockedService<IOptions<MyOptions>>(static o => o.Value.Returns(new MyOptions()))

// Wrong
.AddSingleton<IOptions<MyOptions>>(Options.Create(new MyOptions()))
```

- Never create concrete no-op inner classes to satisfy DI mocking.
- `GetSubstitute<T>()` is safe in `static` Configure methods.

## FunFair.Test.*: Prefer Library Code Over Custom Implementations (MANDATORY)

**Do not write code that FunFair.Test.* already provides.** Before implementing a custom test helper, check what `FunFair.Test.Common` and `FunFair.Test.Infrastructure` offer.

### FunFair.Test.Infrastructure

`FunFair.Test.Infrastructure` is already a transitive dependency of `FunFair.Test.Common`; no explicit `<PackageReference>` is needed.

**`MockBase<T>`** (`FunFair.Test.Infrastructure.Mocks`): as of `FunFair.Test.Common` 6.3.1.2342, `MockBase<T>` moved from `FunFair.Test.Common.Mocks` to `FunFair.Test.Infrastructure.Mocks`. When upgrading to 6.3.1.2342 or later, update the `using` directive in any file that references `MockBase<T>`:

```csharp
// BEFORE (FunFair.Test.Common < 6.3.1.2342)
using FunFair.Test.Common.Mocks;

// AFTER (FunFair.Test.Common >= 6.3.1.2342)
using FunFair.Test.Infrastructure.Mocks;
```

**`HttpClientFactoryExtensions`** (`FunFair.Test.Infrastructure.Extensions`): use `MockCreateClientWithResponse` to set up a named `IHttpClientFactory` substitute with a fixed response; do NOT hand-write `GetSubstitute<IHttpClientFactory>()` + `.Returns()` for simple cases:

```csharp
IHttpClientFactory factory = GetSubstitute<IHttpClientFactory>();
factory.MockCreateClientWithResponse(
    clientName: "MyClientName",
    httpStatusCode: HttpStatusCode.OK,
    responseMessage: """{"data":[]}"""
);
```

Overloads accept `string`, typed object (serialised to JSON), or `HttpStatusCode`-only. Use the typed overload when the response is a .NET object to avoid manual serialisation.

**Limitation**: `MockCreateClientWithResponse` sets up one fixed response per named client. For tests that need sequential different responses from the same client, use `NSubstitute`'s `.Returns()` with a delegate or a custom `HttpMessageHandler`.

### Patterns not to reinvent

- Custom `ILogger<T>` mocks → `this.GetTypedLogger<T>()`
- Custom `TimeProvider` fakes → `FakeTimeProvider` from `Microsoft.Extensions.TimeProvider.Testing`
- Custom `IHttpClientFactory` setups → `MockCreateClientWithResponse`

## xunit Assertion Patterns

`Assert.Single(collection)` returns the single element: capture it directly instead of asserting then indexing:

```csharp
// WRONG
Assert.Single(collection);
var item = collection[0];

// CORRECT
var item = Assert.Single(collection);
```

## Test Date Values (MANDATORY)

Never use hardcoded literal dates (e.g. `new DateTime(2024, 1, 1)`) in tests. Use the `MockDateTimeSources` helpers instead:

| Scenario | Use |
| -------- | --- |
| A date in the past | `MockDateTimeSources.Past` |
| A date in the future | `MockDateTimeSources.Future` |
| A date that advances over time (use sparingly) | `MockDateTimeSources.AdvancingDateTimeUseWithCaution` |

`MockDateTimeSources.AdvancingDateTimeUseWithCaution` advances the clock as the test runs; only use it when the test genuinely requires elapsed time. Prefer `Past` or `Future` for all other cases.

Production code must use `System.TimeProvider` (.NET 8+) for all time abstractions: never `Credfeto.Date.ICurrentTimeSource` or `FunFair.Common.Services.IDateTimeSource` (obsolete). In tests, use `FakeTimeProvider` from `Microsoft.Extensions.TimeProvider.Testing`; never roll a custom mock. Migrate any code touching `ICurrentTimeSource` or `IDateTimeSource` to `TimeProvider`/`FakeTimeProvider` as part of that work.

## Mock Setup Helpers

When a mock setup expression (NSubstitute, Moq, or equivalent) is used in more than one test, extract it into a dedicated `private static` method named `Mock<InterfaceName><MethodName>`, for example, `MockBranchClassificationIsPullRequest`. The helper accepts the mock instance and any variable arguments, and returns the configured mock (or `void` if chaining is not needed). Do not inline the same setup expression across multiple tests.

## Parameterised Tests

Prefer parameterised tests over duplicated test methods: each behavioural variant is a data point, not a separate method. Use xUnit `[Theory]`/`[InlineData]`.

## Test Quality

- Tests must meet the same code quality standards as production code.
- Test behaviour, not implementation: refactoring production code must not unnecessarily break tests.
- Use constants, builders, or factory helpers rather than hardcoded values likely to change.

## Compile-Time Configuration

Cover compile-time configuration (environment constants, build-time feature flags) with unit tests, not runtime assertions, which pollute production code.
