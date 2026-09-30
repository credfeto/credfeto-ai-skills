---
name: credfeto-structured-logging
description: Write structured log statements at the right level, with enough context to diagnose a problem and no PII or secrets; in .NET, use LoggerMessage source generators rather than runtime string-based logging. Use whenever adding or reviewing logging calls, choosing a log level, deciding what to include in a log message, or adding logging to a .NET class.
---

# Structured Logging

## Rules

- Use structured logging: key-value pairs or structured objects, never concatenated strings.
- Log at service/system boundaries (requests, outgoing calls, significant state transitions).
- Log enough context to diagnose a problem without reproducing it: include relevant identifiers and state.
- Never log PII (names, emails, phone numbers, IP addresses, or anything that identifies an individual).
- Never log secrets, credentials, tokens, or passwords.
- Avoid logging large payloads in full; summarise or truncate.

## Log Levels

| Level | Use when |
| --- | --- |
| Error | Unexpected failure; operation could not complete |
| Warning | Unexpected but recoverable; may need investigation |
| Information | Significant business/operational events (service started, job completed) |
| Debug | Detailed diagnostics for development; disabled in production by default |
| Trace | Very fine-grained; never in production |

## .NET: Source-Generated Logging

- Prefer `LoggerMessage` source generators over runtime string-based logging: faster, allocation-free, and compile-time structured.
- Logging methods must be in a dedicated `internal static` class:
  - Placed in a `LoggingExtensions` sub-namespace relative to the class it serves.
  - Named `<ClassName>LoggingExtensions` (e.g. `FooLoggingExtensions` for `Foo`).
- Guard a log call with `if (logger.IsEnabled(<level>))` when any of its arguments is a method call (`.ToString()`, `Stopwatch.GetElapsedTime(...)`, `timer.Successful().TotalMilliseconds`), because C# evaluates the arguments before the generated method's own `IsEnabled` check runs, so the work is done even when the level is disabled (CA1873). Arguments that are plain property or field reads (`algorithm.AlgorithmName`, `network.Name`) need no guard, and CA1873 does not fire on them.
- Put that guard in the logging extensions class, not in the calling code: a `public` method takes the cheap value (a `SimpleExecutionTimer`, or the typed value such as an `AccountAddress` rather than a pre-built `string`), checks `IsEnabled`, and only then computes the expensive part and calls a `private` `[LoggerMessage]` method of the same name that takes the computed value. Callers then log unconditionally and business logic carries no guards.
- Keep `this ILogger<T> logger` as the first parameter of that private method, even though it is private, because FFS0020 (which otherwise requires such parameters to be last, as it does for `CancellationToken`) exempts an extension-style logger parameter. Call it with dot syntax (`logger.LogX(...)`), not as `LogX(logger, ...)`, because CA1873 only recognises the `IsEnabled` guard around a dot-syntax call.
- `[Conditional("DEBUG")]` removes the call itself from every non-DEBUG build, including Release and CI. Pair it with `LogLevel.Debug` only for development-only diagnostics whose arguments are values the method uses anyway, because a local that exists only to feed the call (a timer or `Stopwatch` started earlier) is left unused in Release and fails the build under `TreatWarningsAsErrors`. For diagnostics that must survive into Release, such as those for diagnosing a hang in CI or production, use `LogLevel.Information` without `[Conditional]`. General level choice is in the Log Levels table above.
- Where the project already references `FunFair.Common`, time elapsed-time logging with `FunFair.Common.Metrics.ExecutionTimer.Start()` and `SimpleExecutionTimer.Successful()` rather than raw `Stopwatch.GetTimestamp()`/`GetElapsedTime()`, because those metrics types are the shared convention in those repos.
