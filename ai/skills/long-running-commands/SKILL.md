---
name: credfeto-long-running-commands
description: Run long or unbounded-duration commands (dotnet build, dotnet test, npm test, bun test, git commit/pre-commit/pre-commit-check) safely in the background rather than under a shell timeout wrapper, poll for completion with a reliable string and a time-boxed deadline, distinguish a denied (never-started) command from a killed or in-flight one, and diagnose sandbox-caused false timeouts in benchmark or performance tests. Use whenever about to run one of these commands, whenever using a Monitor-style tool to watch a background task, whenever a tool call is denied by a pre-execution policy hook, or whenever a benchmark/performance test run fails with a timeout-shaped error.
---

# Running Long or Unbounded Commands Safely

## A Hook Denial Is Not a Killed or In-Flight Run (MANDATORY)

Everything below covers polling a command that was **accepted** and is now running. A command rejected outright by a pre-execution policy hook (for example, for missing a required backgrounding parameter) is a different case entirely: it **never started**. There is nothing in flight, and no later notification will ever arrive for it.

- Fix the specific thing the denial names and retry immediately, in the same turn.
- Never end a turn saying you are "waiting for it to finish" or "waiting for a completion notification" for a denied command; that command never ran, so nothing will ever complete. This matters most acutely in a single-shot session: there is no later turn for a notification to land in, so uncommitted work is silently abandoned, but the same misread is just as wrong in an interactive session with turns to spare.
- Use the tool's own backgrounding parameter (`run_in_background: true`), never shell-level backgrounding (`&`, `nohup ... &`, `disown`); shell-level backgrounding is blocked outright by `enforce-background-for-long-running-commands` and produces the same denial-misread-as-in-flight failure.

## Read the Denial's Stated Reason Literally (MANDATORY)

- `git commands must use "git -C <dir>" format` means add `-C <dir>` to that git invocation, not a general git problem.
- `git commit must run with run_in_background: true` means add that tool parameter, not switch to a different commit approach.
- Fixing one hook's violation at a time and retrying can trigger a second hook's denial on the same call, so satisfy every applicable rule in the one call that is retried rather than discovering them one by one. The most common case is a command that must satisfy both a git-invocation-shape hook and a must-be-backgrounded hook at once: `git -C <dir> commit -m "..."` invoked with `run_in_background: true` set on that same tool call.
- Different denials on similar-looking commands usually come from **different** hooks with **different** fixes; do not average them into one general theory (e.g. "backgrounding is broken"). Read the exact hook name and message each time. For example, a plain `dotnet test` without `run_in_background: true` is blocked by `enforce-background-for-long-running-commands`, while the same command with both `run_in_background: true` and a `timeout N` shell wrapper is blocked by `reject-obfuscated-commands` instead (`timeout` is categorically blocklisted): a wrapper-command rejection, unrelated to backgrounding. These are two independent, correctly-working checks, not one contradiction.

## A Permission Denial Is Not a Hook Denial (MANDATORY)

Claude Code has a second way to refuse a command: the permission system itself, sitting above the hook chain. Under `permissions.defaultMode: "dontAsk"`, a command that would normally prompt for approval is auto-denied instead. This is not a `PreToolUse` hook running; no hook name appears anywhere in the message.

Tell the two apart by the message shape, not by guessing at a cause:

- A **hook** denial names the hook and states a reason and a fix, in the shared form `Blocked (command did not run - fix and retry, do not wait for it): <reason>`.
- A **permission** denial names no hook, states no rule, and gives no fix, typically just `Permission to use Bash has been denied because Claude Code is running in don't ask mode.`

Both share one thing: the command **never ran**, so do not wait for it to finish.

- The most common cause of a permission denial is a search command that omits its mandated exclusions for secret-bearing files (`.env`, `.database`, `.claude`). A Bash command naming a directory (`find <dir>`, `grep -r ... <dir>`, `cd <dir> && ...`) is modelled as a read of everything under it; without the exclusions it cannot be proven that a secret-bearing path will not be read, so the call escalates, and under `dontAsk` an escalation comes back as a denial rather than a prompt.
- One command can get a hook denial when run in the foreground (named hook, stated fix) and a permission denial when run in the background (naming neither). These are two different denial shapes, not one broken session.
- Identify which part of the command is being modelled as a broad read, narrow or exclude it, and retry, as the next section requires.

### A `dontAsk` Denial Refuses One Command, Not Bash (MANDATORY)

A `dontAsk` permission denial refuses only the one command it names. The message says "Permission to use Bash", but its scope is that single call: the command text did not match an allow rule, so it escalated, and under `dontAsk` the escalation came back as a denial. Bash stays available, and the next call is judged on its own text.

Never stop the session, report that "Bash is disabled", or treat the task as blocked because of a permission denial: nothing in the environment changed; only that command's shape was refused. Instead:

- **P1.** Rewrite the command in its rule-compliant form and retry it at once, in the same turn. Each of these shapes escalates for the same reason as a search without its exclusions: the permission system cannot prove what the call will touch from its text alone.
  - `git -C <dir> <command>`, not `cd <dir>; git <command>` or `cd <dir> && git <command>`.
  - Literal values, not `$VAR` or any other shell expansion, because an allow rule matches the text as written and cannot see what a variable expands to.
  - One simple command per call, not a `;` or `&&` chain, because every part of a chain must match an allow rule on its own and one unmatched part denies the whole call; make separate tool calls instead.
  - The mandated exclusions for secret-bearing files on every search.
- **P2.** Only if the rule-compliant form is also denied, log it as the next section describes, then carry on with the rest of the task.

### Logging an Allowlist Request (MANDATORY)

A rule-compliant command that the permission system still denies needs a new allow rule, which only the owner can add. Record it where the owner collects these requests, so the need is not lost when the session ends:

- **P1.** Read the comments on credfeto/credfeto-orchestrator#1167 (`gh issue view 1167 --repo credfeto/credfeto-orchestrator --comments`) and check whether the same command, or an allow rule that would cover it, is already listed. If it is, add nothing.
- **P2.** Otherwise, comment on credfeto/credfeto-orchestrator#1167 with the exact denied command, why the task needs it, and the repository the session is working in.
- **P3.** Continue with the rest of the task. The request is for the owner to act on later; it does not block the current work.

## Never Truncate These Commands (MANDATORY)

`git commit`/`pre-commit`/`pre-commit-check`, `dotnet build`, `dotnet test`, `npm test`, and `bun test` have no bounded, predictable duration: `pre-commit` (and `pre-commit-check`, a wrapper that runs it against the existing checked-out repo) can run a heavy hook chain, `dotnet build` runs through a large analyzer stack plus package restore, and test runs scale with what changed. There is no timeout value that is both practical and safe to pick for any of these commands, so do not try to pick one.

- **Always run these commands via a background-task mechanism (e.g. `run_in_background`); never in the foreground, regardless of how fast the specific run is expected to be.** This is unconditional, not a per-invocation judgement call.
- **Never wrap any of these in a shell `timeout` command as a substitute or a belt-and-braces addition** (e.g. `timeout 590 dotnet test ...`), whether or not the background-task mechanism is also used. `timeout` is on the categorical blocklist of the `reject-obfuscated-commands` hook and is rejected outright, independently of the backgrounding rule: running the command unwrapped and backgrounded is already unbounded and needs no additional wrapper. A missing backgrounding parameter and a banned `timeout` wrapper are denied by different hooks and are unrelated; read which hook actually fired rather than assuming a single general conflict.
- Poll for completion using the reliable strings in the table below, subject to the 30-minute deadline in [Time-Box Every Poll Loop](#time-box-every-poll-loop-mandatory) below.
- **A long stretch with no new output is normal and is not a hang.** Do not interpret silence as a failure and manually cancel or kill the command on that basis. Never stop waiting for the completion marker: when the poll-loop deadline fires, report and keep waiting as the time-box section describes, and when a `Monitor` watch's own timeout expires first, start a new watch.
- A killed run does not just fail; it skips the target process's own cleanup (a bash `EXIT` trap, .NET's `IDisposable` teardown, etc.), leaving orphaned temp directories, lock files, or half-applied state behind. Orphaned temp directories under a shared path can break other tools that walk the same path.
- Other `dotnet` commands (`dotnet restore`, a standalone `dotnet buildcheck`, `dotnet format`, etc.) are not covered by this unconditional rule; they may run in the foreground, but **always with an explicit maximum timeout set on the tool call**, never the tool's built-in default (e.g. Claude Code's Bash tool defaults to 2 minutes when no `timeout` is given; use the maximum available, e.g. 600000ms/10 minutes, explicitly). If even that maximum is not enough, use `run_in_background` and the Monitor tool instead of accepting a truncated run.

### Finishing Background Work Before Handing Back

- **P1.** A role never hands back while a background command it started (a build, a test run, `pre-commit-check`, or a commit or push that runs hooks) is still running: it waits for the command's completion marker. It never stops such a command with `TaskStop`, because the command must finish and clean up after itself, and killing it can leave a stale `.git/index.lock`, partial build output or a push in an unknown state. If the command overruns the poll deadline, the role still neither hands back nor stops it: it reports the overrun as the time-box section describes and keeps waiting for the completion marker, because in an unattended `-p` run handing back kills a background command about five seconds later (see P3), leaving the half-done state this rule prevents.
- **P2.** A role that starts a `Monitor` watch records the task id `Monitor` returns, and a role that paces a wait with a `ScheduleWakeup` self-paced loop instead notes that it is using one, because the stop step in P3 needs it: `TaskStop` takes the watch's task id, and a self-paced loop is stopped a different way. When a role starts a replacement watch, for example after the previous one expired, it records the new task id, because only the latest watch is still running.
- **P3.** Once the command, or the condition a watch was waiting for, has finished, the role stops any `Monitor` watch or `ScheduleWakeup` self-paced loop it started before handing back: `TaskStop` with the task id recorded in P2 for a `Monitor` watch, `ScheduleWakeup` with `stop: true` for a self-paced loop. This is because a watch left running outlives the hand-back in both run modes: in an interactive session a background sub-agent's tasks keep running until they finish, are stopped or time out, and every tick of the watch re-wakes the sub-agent and forces another hand-back; in an unattended `-p` run a background command is killed about five seconds after the final result, but a `Monitor` watch keeps the run open, up to a ten-minute cap.
- **P4.** `TaskStop` is for watches only, because a watch only observes and loses nothing when stopped. The one other use is the Orchestrator's, on a sub-agent that has already delivered its final report and is only repeating it.

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
3. **Verify the poll string exists in real output before writing the loop.** If you cannot confirm what string the command writes, run the command in the foreground first and read its output.
4. **Prefer foreground for quick, bounded commands** (`git status`, a single `grep`, `ls`, and similar). Always background the commands listed above regardless of expected speed; use `run_in_background: true` for any other command that genuinely takes many minutes (e.g. a full integration-test run) when there is independent work to do while waiting.

### Time-Box Every Poll Loop (MANDATORY)

Time-box every poll loop to 30 minutes. The deadline ends one poll loop so a command that is taking unusually long is reported instead of waited on silently; it never ends the wait, and never the command. The loop below is the command passed to the `Monitor` tool, never an ad-hoc Bash call, because an ad-hoc compound command can be refused by a `dontAsk` permission denial; the loop exiting, on the marker or on the deadline, ends only that watch, never the watched command, which runs as its own background task:

```bash
deadline=$(( $(date +%s) + 1800 ))
until grep -q "Build succeeded." "${output_file}" 2>/dev/null; do
    sleep 15
    if [ "$(date +%s)" -ge "${deadline}" ]; then
        echo "Still waiting after 30 minutes for build" >&2
        exit 1
    fi
done
```

When the deadline fires, the role does not hand back and does not stop the command; it reports the overrun and then starts a new `Monitor` watch on the same completion marker:

- In an interactive session, tell the human the command is still running and which completion marker the role is waiting for.
- In an unattended run, post the same as a comment on the work item, without the `Blocked` label, because the role is still working rather than waiting on a human:

  ```bash
  gh issue comment <number> --repo <owner/repo> \
      --body "Still waiting after 30 minutes for <what> (completion marker: <marker>); the command is still running. Last output: $(tail -5 "${output_file}" 2>/dev/null)"
  ```

  Use `gh pr comment` instead if the work item is a PR.

## Sandbox-Caused False Timeouts in Benchmark/Perf Tests (MANDATORY)

If a `dotnet test`/`dotnet build` run that includes a benchmark or performance-test project fails with a timeout-shaped error (e.g. "configured timeout ... reached", "command took longer than the timeout", "Failed to set up high priority (Permission denied)"), do not conclude this is a genuine pre-existing or environmental limitation in the codebase before ruling out your own execution sandbox as the cause:

1. Re-run the identical command with sandboxing disabled if your tool supports it (e.g. a `dangerouslyDisableSandbox`-style flag).
2. Reproducing the same failure on a clean `main`/base branch does **not** rule out the sandbox; if you're still running inside the same sandboxed shell, that reproduction is confounded and proves nothing about the codebase itself.
3. If the failure disappears or measurably improves with sandboxing disabled, the sandbox was throttling CPU/resources; report this plainly; do not describe the benchmark suite as broken or flaky.
4. If still uncertain after disabling sandboxing, say so explicitly and ask the user to run the identical command in their own terminal before asserting any diagnosis; never present a sandbox artifact as a confirmed pre-existing bug.
