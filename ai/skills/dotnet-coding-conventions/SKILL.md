---
name: credfeto-dotnet-coding-conventions
description: Follow .NET identifier naming conventions, prefer StringComparer over string.Equals with a StringComparison, keep one type per file matching the file name, use positional records or readonly record structs instead of hand-written data classes, prefer struct/record struct for small immutable values, add DebuggerDisplay attributes, prefer ValueTask and propagate CancellationToken through async code, and never modify nuget.config. Use whenever writing or reviewing .NET production code.
---

# .NET Coding Conventions

## Configuration (MANDATORY)

- Never modify `nuget.config`; it is managed by the repo owner, not by AI.

## Naming Conventions

| Identifier | Convention | Example |
| ---------- | ---------- | ------- |
| Private constants (`const`) | `UPPER_SNAKE_CASE` | `private const int MAX_RETRY_COUNT = 3;` |
| Enum members | `UPPER_SNAKE_CASE` | `NO_REFERRER_WHEN_DOWNGRADE` |
| Private instance fields | `_camelCase` | `private readonly string _emailAddress;` |
| Private static readonly fields | `PascalCase` | `private static readonly Regex HostRegex = ...;` |
| Public/internal constants (`const`) | `PascalCase` | `public const int MaximumStringLength = 255;` |
| Public/internal properties | `PascalCase` | `public int PageSize { get; }` |
| Public/internal methods | `PascalCase` | `public bool TryParse(...)` |
| Local variables | `camelCase` | `int retryCount = 0;` |
| Method parameters | `camelCase` | `void Method(int retryCount, ...)` |
| Interfaces | `IPascalCase` | `IHostedBackgroundService` |
| Type parameters (generics) | `TPascalCase` | `<TKey, TValue>` |

## String Comparison

- Prefer `StringComparer.<type>.Equals(x, y)` over `string.Equals(x, y, StringComparison.<type>)`.
- This applies to all `StringComparison` variants (`Ordinal`, `OrdinalIgnoreCase`, etc.).
- Do not use `StringComparison.InvariantCulture`, `StringComparison.InvariantCultureIgnoreCase`, `StringComparison.CurrentCulture`, or `StringComparison.CurrentCultureIgnoreCase`.

## Source File Organisation

- One type per file: class, record, struct, interface, or enum.
- File name must match the type name exactly (e.g. `FooBar.cs` for `class FooBar`).

## Data Types: Prefer Records over Classes

Use a positional `record` (or `readonly record struct`) instead of a hand-written data class wherever the type is a pure carrier of data with no behaviour.

```csharp
// WRONG: hand-written data class
public sealed class GlobalJsonInfo
{
    public GlobalJsonInfo(string? sdkVersion, string? rollForward, bool? allowPrerelease)
    {
        this.SdkVersion = sdkVersion;
        this.RollForward = rollForward;
        this.AllowPrerelease = allowPrerelease;
    }

    public string? SdkVersion { get; }
    public string? RollForward { get; }
    public bool? AllowPrerelease { get; }
}

// CORRECT: positional record
[DebuggerDisplay("SdkVersion={SdkVersion}, RollForward={RollForward}, AllowPrerelease={AllowPrerelease}")]
public sealed record GlobalJsonInfo(string? SdkVersion, string? RollForward, bool? AllowPrerelease);
```

- Always add `[DebuggerDisplay("...")]` showing all key properties (see Debugger Diagnostics below).
- If the type is a pure value (no identity semantics, small, immutable) prefer `readonly record struct` over `record class`.
- If the target framework does **not** support records (e.g. `netstandard2.0`), continue using a `class` or `struct`, but manually implement everything a record would provide: a constructor that sets all properties, read-only auto-properties, `Equals`, `GetHashCode`, `ToString`, and `IEquatable<T>`.

## Asynchronous Code and Cancellation

- Prefer async over sync wherever supported; never block on async operations (always await or use async continuations); propagate async through the call stack, with no synchronous wrappers around async operations.
- Prefer `ValueTask`/`ValueTask<T>` over `Task`/`Task<T>`: avoids heap allocations on synchronous-completion paths. Only use `Task`/`Task<T>` where `ValueTask` is unsupported or the method always completes asynchronously.
- All async methods must accept and pass down a `CancellationToken`; prefer overloads that accept one.
- Never create a new `CancellationToken` when one has been provided, unless combining with a timeout via `CancellationTokenSource.CreateLinkedTokenSource`.
- Do not pass `CancellationToken.None` without an explicit documented reason.

## Value Types (struct / record struct)

- Prefer `struct` or `record struct` over `class` for small, short-lived, immutable data; avoids heap allocations.
- Use `struct` when the type is logically a value (not an identity), is generally small, and is frequently created/discarded.
- Prefer `readonly struct` or `readonly record struct` to enforce immutability and enable compiler optimisations.
- Avoid mutable structs; unexpected copy semantics cause subtle bugs.
- Do not use `struct` for types that need inheritance or will be boxed frequently.

## Debugger Diagnostics

- All value types (`struct`, `record struct`, records with positional parameters) must have `[DebuggerDisplay("...")]` showing key fields.
- All configuration/options classes must have `[DebuggerDisplay("...")]` showing key properties.
