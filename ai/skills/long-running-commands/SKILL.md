---
name: credfeto-long-running-commands
description: Run long or unbounded-duration commands (dotnet build, dotnet test, npm test, bun test, git commit/pre-commit, git push) safely in the background, poll for completion with a reliable string and a time-boxed deadline, distinguish a denied (never-started) command from a killed or in-flight one, and diagnose sandbox-caused false timeouts in benchmark or performance tests. Use whenever about to run one of these commands, whenever using a Monitor-style tool to watch a background task, whenever a tool call is denied by a pre-execution policy hook, or whenever a benchmark/performance test run fails with a timeout-shaped error.
---

# Running Long or Unbounded Commands Safely

## A Hook Denial Is Not a Killed or In-Flight Run (MANDATORY)

Everything below covers polling a command that was **accepted** and is now running. A command rejected outright by a pre-execution policy hook (for example, for missing a required backgrounding parameter) is a different case entirely: it **never started**. There is nothing in flight, and no later notification will ever arrive for it.

- Fix exactly what the denial states (e.g. add the missing backgrounding parameter) and retry immediately, in the same turn.
- Never end a turn saying you are "waiting for it to finish" or "waiting for a completion notification" for a denied command; that command never ran, so nothing will ever complete.
- Prefer the tool's own backgrounding parameter (e.g. `run_in_background: true`) over shell-level backgrounding (`&`, `nohup ... &`, `disown`); shell-level backgrounding is commonly blocked outright by this same class of hook and produces the identical denial-misread-as-in-flight failure.

## Never Truncate These Five Commands (MANDATORY)

`git commit`/`pre-commit`, `dotnet build`, `dotnet test`, `npm test`, and `bun test` have no bounded, predictable duration: `pre-commit` can run a heavy hook chain, `dotnet build` runs through a large analyzer stack plus package restore, and test runs scale with what changed. A commit or test run can be killed mid-run by a foreground timeout. There is no timeout value that is both practical and safe to pick for any of these five commands, so do not try to pick one.

- **Always run these five commands via a background-task mechanism (e.g. `run_in_background`); never in the foreground, regardless of how fast the specific run is expected to be.** This is unconditional, not a per-invocation judgement call.
- Poll for completion using the reliable strings in the table below, subject to the 30-minute deadline in [Time-Box Every Poll Loop](#time-box-every-poll-loop-mandatory) below.
- **A long stretch with no new output is normal and is not a hang.** Do not interpret silence as a failure and manually cancel or kill the command on that basis. The only valid reasons to stop waiting are: the tool itself reports its timeout was hit, or the poll-loop deadline actually fires.
- A killed run does not just fail; it skips the target process's own cleanup (a shell `EXIT` trap, a runtime's `IDisposable`-style teardown, etc.), leaving orphaned temp directories, lock files, or half-applied state behind. A killed test run has left thousands of orphaned fixture directories under a shared runtime directory in practice, which went on to break an unrelated tool that walked the same path; a commit has separately been killed mid-run on a foreground timeout.
- Other commands from the same toolchain (`dotnet restore`, a standalone `dotnet buildcheck`, `dotnet format`, etc.) are not covered by this unconditional rule; they may run in the foreground, but **always with an explicit maximum timeout set on the tool call**, never the tool's built-in default (many shell tools default to a short timeout, e.g. 2 minutes, when none is given; set the maximum available explicitly, e.g. 600000ms/10 minutes). If even that maximum is not enough, background the command and poll instead of accepting a truncated run.

### Reliable poll strings by command

| Command / scenario | String to poll for |
| --- | --- |
| `dotnet build` succeeded | `Build succeeded.` |
| `dotnet test` all passed | `Passed!` |
| pre-commit hooks passed | `→ All checks passed.` |
| pre-commit hooks failed | `→` followed by `Failed` (check for both to distinguish pass/fail) |
| `git push` completed | `branch` (branch tracking line in push output) |
| `gh pr create` / `gh pr ready` | poll not needed: these exit immediately |

## Rules for Poll Conditions (MANDATORY)

When watching a background task, the poll condition **must** be provably satisfiable; a condition that can never be met loops forever and blocks the whole session.

1. **Never poll for `"exit code"`**; that string is not reliably written to background task output files. Poll for a specific string the command itself writes (see table above).
2. **Do not pipe after `grep -q` in a negation check.** `! grep -q "pattern" file | tail -1` does NOT detect absence: the pipe applies to grep's (empty) stdout, so `tail -1` exits 0 regardless, and `!` inverts that to always-false. Write `! grep -q "pattern" file` with no trailing pipe.
3. **Verify the poll string exists in real output before writing the loop.** If you cannot confirm what string the command writes, run it in the foreground first (for a command that is safe to run in the foreground) and read its output, or consult its documentation.
4. **Prefer foreground only for quick, bounded commands** (`git status`, a single `grep`, `ls`, and similar). Always background the five commands above regardless of expected speed; background any other command that genuinely takes many minutes (e.g. a full integration-test run) when there is independent work to do while waiting.

### Time-Box Every Poll Loop (MANDATORY)

Always include a deadline so the session cannot hang forever:

```bash
deadline=$(( $(date +%s) + 1800 ))
until grep -q "Build succeeded." "${output_file}" 2>/dev/null; do
    sleep 15
    if [ "$(date +%s)" -ge "${deadline}" ]; then
        echo "ERROR: timed out after 30 minutes waiting for build" >&2
        exit 1
    fi
done
```

If the deadline fires, mark the work item Blocked and stop; do not continue work:

```bash
gh issue edit <number> --repo <owner/repo> --add-label "Blocked"
gh issue comment <number> --repo <owner/repo> \
    --body "Blocked: timed out after 30 minutes waiting for <what>. Last output: $(tail -5 "${output_file}" 2>/dev/null)"
```

Use `gh pr edit` / `gh pr comment` instead if the work item is a PR. Then exit; do not continue work.

## Sandbox-Caused False Timeouts in Benchmark/Perf Tests (MANDATORY)

If a `dotnet test`/`dotnet build` run that includes a benchmark or performance-test project fails with a timeout-shaped error (e.g. "configured timeout ... reached", "command took longer than the timeout", "Failed to set up high priority (Permission denied)"), do not conclude this is a genuine pre-existing or environmental limitation in the codebase before ruling out your own execution sandbox as the cause:

1. Re-run the identical command with sandboxing disabled if your tool supports it (e.g. a `dangerouslyDisableSandbox`-style flag).
2. Reproducing the same failure on a clean `main`/base branch does **not** rule out the sandbox; if you're still running inside the same sandboxed shell, that reproduction is confounded and proves nothing about the codebase itself.
3. If the failure disappears or measurably improves with sandboxing disabled, the sandbox was throttling CPU/resources; report this plainly; do not describe the benchmark suite as broken or flaky.
4. If still uncertain after disabling sandboxing, say so explicitly and ask the user to run the identical command in their own terminal before asserting any diagnosis; never present a sandbox artifact as a confirmed pre-existing bug.
