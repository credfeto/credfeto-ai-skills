---
name: credfeto-performance-benchmarking
description: Design and optimise performance-critical code, and back optimisations with committed benchmarks and measured allocation thresholds. Use when writing or optimising performance-critical code, or when asked to add or update a benchmark.
---

# Performance Design and Benchmarking

## Design and Code

- Optimise for speed first, then memory (allocations).
- Prefer algorithms and data structures with better time and space complexity.
- Avoid unnecessary allocations — reuse instances, use pooling for frequently allocated objects.
- Avoid copying data unnecessarily — work in-place or pass by reference where safe.
- Avoid blocking calls on hot paths — prefer async.
- Avoid high-level abstractions (functional pipelines, heavy reflection, dynamic dispatch) on hot paths; prefer lower-level constructs.
- Use low-allocation APIs when processing strings or buffers.
- Cache expensive computed values that do not change within a given scope.
- Be mindful of implicit conversions, boxing, or type coercions on hot paths.

## Benchmark Workflow (MANDATORY for performance-critical code)

1. **Write benchmarks alongside the code they measure** — commit them in the same or an adjacent commit, never as an afterthought.
   - In .NET repositories, write benchmarks as xUnit tests in the benchmark test project (`<AssemblyName>.Benchmark.Tests`), using `FunFair.Test.Common` helpers: `Benchmark<BenchmarkClass>()` to run the benchmark and `SummaryExtensions.AssertAllocationsAtMost(...)` to assert measured thresholds (zero or explicit byte threshold). Do not roll custom benchmark or allocation-measurement helpers.
2. **Ensure tests and benchmarks pass before optimising** — commit them first as a standalone commit, establishing a baseline.
3. **Record the baseline** — regressions against it are not acceptable.
4. **Optimise**, then re-run the benchmark.
5. **Only commit the optimisation if it produces a measurable gain against the baseline** — otherwise discard the optimisation but keep the tests and benchmarks that were written to characterise it.

**Never run `dotnet test` or `dotnet run` directly on a `*.Benchmark.Tests` project** — BenchmarkDotNet performs real measurements that take hours and spawn dozens of build processes. CI handles benchmark execution; never run benchmarks manually.

## Environment Variables

- `FUNFAIR_TEST_BENCHMARK_BUILD_TIMEOUT_SECONDS` — overrides how long BenchmarkDotNet is allowed to spend building the isolated host project it generates for each benchmark, in `*.Benchmark.Tests` projects. Default: `600` (10 minutes).
  - Raise it when a benchmark run fails during the *build* phase (not the measurement phase) purely because the environment is slow — e.g. a virtual machine or a constrained CI runner — not to mask a genuine regression.
  - If raising this value is what makes a build/test run pass, comment on the PR stating the value that was required, so the default can be reconsidered for that environment.
