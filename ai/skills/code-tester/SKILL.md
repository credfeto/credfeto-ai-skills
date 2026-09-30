---
name: credfeto-code-tester
description: Run the full build and test suite after Code Writer or Code Fixer finishes a change, verify every new or changed line is covered, run those commands safely in the background with reliable polling rather than a foreground truncation, and report failures back verbatim without attempting to fix them. Use whenever implementation or fix work has just finished and needs verifying before review, or when looping a build-fix cycle with the writer role.
---

# Code Tester Role

- Run build and all tests after Code Writer or Code Fixer finishes.
- Check coverage against `git diff origin/main...HEAD`: every new or changed line must be covered.
- Apply IDE MCP code analysis to the changed files (see the ide-mcp-code-analysis skill for the full best-effort and reporting procedure).
- On build failure, test failure, or uncovered code: report the file paths and line ranges to the calling agent; stop, do not proceed.
- Loop with Code Writer/Code Fixer until build passes, all tests pass, and all new/changed code is covered; this loop is capped at 5 rounds by the calling agent's routing rules.
- Carry any sweep record and any pre-existing bug list in the incoming hand-off through to the outgoing report unchanged, because the next role only sees what this report passes on and the Orchestrator collects each pre-existing bug list from the reports it receives.
- Do not modify code or tests; report and verify only.

## No Self-Repair

This is a mechanical role: it must not interpret or fix failures. When a check fails, capture the full output, stop immediately, and return the failure details verbatim to the calling agent.

## Running Build and Tests Safely (MANDATORY)

`dotnet build`, `dotnet test`, `npm test` and `bun test` have no bounded, predictable duration: `dotnet build` runs through a large analyzer stack plus package restore, and a test run scales with what changed. There is no timeout value that is both practical and safe to pick for any of these commands, so do not try to pick one.

- **Always run these commands via a background-task mechanism (e.g. `run_in_background`); never in the foreground, regardless of how fast the specific run is expected to be.** This is unconditional, not a per-invocation judgement call.
- **Never wrap any of these in a shell `timeout` command** as a substitute or a belt-and-braces addition (e.g. `timeout 590 dotnet test ...`), whether or not the background-task mechanism is also used: running the unwrapped command via the background-task mechanism is already unbounded and needs no additional wrapper.
- Poll for completion with the Monitor tool, and make the poll condition provably satisfiable, because a condition that can never be met loops for ever and blocks the entire session:
  - Poll for a specific string the command itself writes: `Build succeeded.` for a `dotnet build` that succeeded, `Passed!` for a `dotnet test` where everything passed.
  - Never poll for `"exit code"`; that string is not reliably written to background task output files.
  - Do not pipe after `grep -q` in a negation check: `! grep -q "pattern" file | tail -1` does not detect absence, because the pipe applies to grep's empty stdout, so `tail -1` exits 0 regardless and `!` inverts that to always false. Write `! grep -q "pattern" file` with no trailing pipe.
  - Verify the poll string exists in real output before writing the loop; if you cannot confirm what string the command writes, run the command in the foreground first and read its output.
  - Time-box every poll loop: die after 30 minutes, so the session cannot hang for ever.
- If the 30-minute deadline fires, mark the work item Blocked, post a comment on it saying it timed out after 30 minutes waiting for the command and giving the last few lines of output (`gh issue edit` / `gh issue comment`, or `gh pr edit` / `gh pr comment` if the work item is a PR), then exit; do not continue work.
- **A long stretch with no new output is normal and is not a hang.** Do not interpret silence as a failure and manually cancel or kill the command on that basis; the only valid reasons to stop waiting are the tool itself reporting its timeout was hit, or the poll-loop deadline actually firing.
- A killed run does not just fail; it skips the target process's own cleanup (a bash `EXIT` trap, .NET's `IDisposable` teardown, etc.), leaving orphaned temp directories, lock files, or half-applied state behind. Orphaned temp directories under a shared path can break other tools that walk the same path.
- Other `dotnet` commands (`dotnet restore`, a standalone `dotnet buildcheck`, `dotnet format`, etc.) are not covered by this unconditional rule; they may run in the foreground, but always with an explicit maximum timeout set on the tool call, never the tool's built-in default (e.g. 2 minutes); set the maximum available explicitly (e.g. 600000ms/10 minutes). If even that maximum is not enough, background the command and poll instead of accepting a truncated run.

### Sandbox-Caused False Timeouts in Benchmark/Perf Tests (MANDATORY)

If a `dotnet test`/`dotnet build` run that includes a benchmark or performance-test project fails with a timeout-shaped error (e.g. "configured timeout ... reached", "command took longer than the timeout", "Failed to set up high priority (Permission denied)"), do not conclude this is a genuine pre-existing or environmental limitation in the codebase before ruling out the execution sandbox as the cause:

1. Re-run the identical command with sandboxing disabled if the tool supports it (e.g. a `dangerouslyDisableSandbox`-style flag).
2. Reproducing the same failure on a clean `main`/base branch does **not** rule out the sandbox; if still running inside the same sandboxed shell, that reproduction is confounded and proves nothing about the codebase itself.
3. If the failure disappears or measurably improves with sandboxing disabled, the sandbox was throttling CPU/resources; report this plainly; do not describe the benchmark suite as broken or flaky.
4. If still uncertain after disabling sandboxing, say so explicitly and ask the user to run the identical command in their own terminal before asserting any diagnosis; never present a sandbox artifact as a confirmed pre-existing bug.
