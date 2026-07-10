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

## NSubstitute and FunFair.Test.Common Patterns

| Instead of | Use |
| ---------- | --- |
| `Substitute.For<IMyInterface>()` | `GetSubstitute<IMyInterface>()` (static — no `this.`) |
| `Substitute.For<ILogger<MyClass>>()` | `this.GetTypedLogger<MyClass>()` (instance — requires `this.`) |

- Never call `Substitute.For<T>()` in classes deriving from `TestBase` or `DependencyInjectionTestsBase`.
- Remove unused `using NSubstitute;` after replacing all `Substitute.For<>()` calls.
- All instance method calls on `TestBase` (including `GetTypedLogger<T>()`, `GetSubstitute<T>()`, `CancellationToken()`, and custom helpers) require explicit `this.` — IDE0009 is enforced as an error. Static helpers (e.g. `GetSubstitute<T>()`) must remain `static` to avoid this requirement.

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

## FunFair.Test.* — Prefer Library Code Over Custom Implementations (MANDATORY)

**Do not write code that FunFair.Test.* already provides.** Before implementing a custom test helper, check what `FunFair.Test.Common` and `FunFair.Test.Infrastructure` offer.

### FunFair.Test.Infrastructure

`FunFair.Test.Infrastructure` is already a transitive dependency of `FunFair.Test.Common` — no explicit `<PackageReference>` is needed.

**`MockBase<T>`** (`FunFair.Test.Infrastructure.Mocks`): as of `FunFair.Test.Common` 6.3.1.2342, `MockBase<T>` moved from `FunFair.Test.Common.Mocks` to `FunFair.Test.Infrastructure.Mocks`. When upgrading to 6.3.1.2342 or later, update the `using` directive in any file that references `MockBase<T>`:

```csharp
// BEFORE (FunFair.Test.Common < 6.3.1.2342)
using FunFair.Test.Common.Mocks;

// AFTER (FunFair.Test.Common >= 6.3.1.2342)
using FunFair.Test.Infrastructure.Mocks;
```

**`HttpClientFactoryExtensions`** (`FunFair.Test.Infrastructure.Extensions`): use `MockCreateClientWithResponse` to set up a named `IHttpClientFactory` substitute with a fixed response — do NOT hand-write `GetSubstitute<IHttpClientFactory>()` + `.Returns()` for simple cases:

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

`Assert.Single(collection)` returns the single element — capture it directly instead of asserting then indexing:

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

`MockDateTimeSources.AdvancingDateTimeUseWithCaution` advances the clock as the test runs — only use it when the test genuinely requires elapsed time. Prefer `Past` or `Future` for all other cases.

Production code must use `System.TimeProvider` (.NET 8+) for all time abstractions — never `Credfeto.Date.ICurrentTimeSource` or `FunFair.Common.Services.IDateTimeSource` (obsolete). In tests, use `FakeTimeProvider` from `Microsoft.Extensions.TimeProvider.Testing` — never roll a custom mock.

## Mock Setup Helpers

When a mock setup expression (NSubstitute, Moq, or equivalent) is used in more than one test, extract it into a dedicated `private static` method named `Mock<InterfaceName><MethodName>` — for example, `MockBranchClassificationIsPullRequest`. The helper accepts the mock instance and any variable arguments, and returns the configured mock (or `void` if chaining is not needed). Do not inline the same setup expression across multiple tests.

## Parameterised Tests

Prefer parameterised tests over duplicated test methods — each behavioural variant is a data point, not a separate method. Use xUnit `[Theory]`/`[InlineData]`.

## Test Quality

- Tests must meet the same code quality standards as production code.
- Test behaviour, not implementation — refactoring production code must not unnecessarily break tests.
- Use constants, builders, or factory helpers rather than hardcoded values likely to change.
