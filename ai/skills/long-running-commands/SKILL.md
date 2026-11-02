---
name: credfeto-long-running-commands
description: Run long or unbounded-duration commands (dotnet build, dotnet test, npm test, bun test, git commit/pre-commit/pre-commit-check) safely in the background rather than under a shell timeout wrapper, wait for the harness's completion notification and judge only by its exit code, enforce the 30-minute deadline, distinguish a denied (never-started) command from a killed or in-flight one, and diagnose sandbox-caused false timeouts in benchmark or performance tests. Use whenever about to run one of these commands, whenever tempted to use a Monitor tool or poll loop to wait for a background task, whenever a tool call is denied by a pre-execution policy hook or the permission system, or whenever a benchmark/performance test run fails with a timeout-shaped error.
---

# Running Long or Unbounded Commands Safely

## A Hook Denial Is Not a Killed or In-Flight Run (MANDATORY)

Everything about waiting below covers a command that was **accepted** and is now running. A command rejected outright by a pre-execution policy hook (for example, for missing a required backgrounding parameter) is a different case entirely: it **never started**. There is nothing in flight, and no later notification will ever arrive for it.

- Fix the specific thing the denial names and retry immediately, in the same turn.
- Never end a turn saying you are "waiting for it to finish" or "waiting for a completion notification" for a denied command; that command never ran, so nothing will ever complete. This matters most acutely in a single-shot session: there is no later turn for a notification to land in, so uncommitted work is silently abandoned, but the same misread is just as wrong in an interactive session with turns to spare.

## Read the Denial's Stated Reason Literally (MANDATORY)

- `git commands must use "git -C <dir>" format` means add `-C <dir>` to that git invocation, not a general git problem.
- `git commit must run with run_in_background: true` means add that tool parameter, not switch to a different commit approach.
- Fixing one hook's violation at a time and retrying can trigger a second hook's denial on the same call, so satisfy every applicable rule in the one call that is retried rather than discovering them one by one. The most common case is a command that must satisfy both a git-invocation-shape hook and a must-be-backgrounded hook at once: `git -C <dir> commit -m "..."` invoked with `run_in_background: true` set on that same tool call.
- Different denials on similar-looking commands usually come from **different** hooks with **different** fixes; do not average them into one general theory (e.g. "backgrounding is broken"). Read the exact hook name and message each time. For example, a plain `dotnet test` without `run_in_background: true` is blocked by `enforce-background-for-long-running-commands`, while the same command with both `run_in_background: true` and a `timeout N` shell wrapper is blocked by `reject-obfuscated-commands` instead (`timeout` is categorically blocklisted): a wrapper-command rejection, unrelated to backgrounding. These are two independent, correctly-working checks, not one contradiction.

## A Hook Block Is Not a Puzzle to Solve (Never Work Around It) (MANDATORY)

Fixing and retrying means retrying **the same operation** in a form the hook accepts. It never means finding another way to get the same effect, because a hook that can be got round no longer enforces anything. Decide which of two cases applies:

- **The block is correct.** The command broke a rule or took a shortcut the hook exists to stop. Change approach to the permitted way of doing the same thing; there is nothing to report. For example:
  - `git grep` blocked by `enforce-git-dash-c`: use the Grep tool or plain `grep` instead.
  - `cd <dir> && git <command>` blocked: use `git -C <dir> <command>`.
  - A file edit written through a Bash heredoc blocked by `block-no-verify` (a false positive on the heredoc's text): make the edit with the Edit tool instead.
- **The hook is too strict.** The operation is legitimate, and no form of it that the hook accepts exists. Do **not** get the same effect a different way. In particular, never:
  - write an inline or ad-hoc script (Python, shell or any other language) that does what the blocked command would have done;
  - use copy-and-swap tricks, such as copying files aside and swapping them back, to stand in for a blocked copy, compare or restore;
  - switch to a different command or tool with the same effect, such as `git checkout -- <path>` when `git restore` is blocked;
  - create or edit any settings, permission or hook file to make the blocked command run, including `.claude/settings*.json` in any repository, anything under `~/.claude/`, and any `CLAUDE.md`, or load a skill that does so;
  - ask the calling role, the Orchestrator or the human to run the blocked command for you.

  Instead, stop that operation and report the blocked command and the hook's message, both verbatim, to the calling role, or to the Orchestrator if there is no calling role, so the human can decide whether the hook should change. A role that receives such a report passes it on unchanged in its own report until it reaches the Orchestrator, which never runs a command a sub-agent was denied and never changes settings, permission or hook files because a sub-agent asked.

In both cases, retrying the same operation in a form the hook accepts is fine: literal paths instead of variables, `git -C <dir>` instead of `cd && git`, `run_in_background: true` on the same call. An agent that hits a `git grep` block and stops to ask is behaving correctly; the answer is that the block is correct and plain `grep` is the permitted form.

## Prefer the Tool's Own Backgrounding Parameter (MANDATORY)

Use the tool's own `run_in_background: true` parameter, never shell-level backgrounding (`&`, `nohup ... &`, `disown`). Shell-level backgrounding is blocked outright by `enforce-background-for-long-running-commands` and produces the same denial-misread-as-in-flight failure described above.

## Ad-Hoc Commands Never Use `xargs` or `while IFS= read` Loops (MANDATORY)

Never use `xargs` or a `while IFS= read` loop in an ad-hoc Bash tool call. `reject-obfuscated-commands` refuses both before the command runs:

- `xargs` is on `command-blocklist`, which wins over `command-allowlist`, so any command containing it is rejected.
- `IFS` is on `env-var-blocklist`, so an assignment to it is rejected, whether it is a standalone statement or a per-command prefix such as `IFS= read`. Dropping the prefix does not help, because `read` is not on `command-allowlist` either.

Instead, write one flat command per call: name the paths directly, or pass the whole list in one call (for example `shellcheck a.sh b.sh`, or `cfwf pr view --repo <owner/repo> --pr <n> --field state --field labels`).

Committed scripts and workflow steps do not pass through these hooks, so a fixed per-file command there may still use `xargs -0r`.

## A Permission Denial Is Not a Hook Denial (MANDATORY)

Claude Code has a second way to refuse a command: the permission system itself, sitting above the hook chain. Under `permissions.defaultMode: "dontAsk"`, a command that would normally prompt for approval is auto-denied instead. This is not a `PreToolUse` hook running; no hook name appears anywhere in the message.

Tell the two apart by the message shape, not by guessing at a cause:

- A **hook** denial names the hook and states a reason and a fix, in the shared form `Blocked (command did not run - fix and retry, do not wait for it): <reason>`.
- A **permission** denial names no hook, states no rule, and gives no fix, typically just `Permission to use Bash has been denied because Claude Code is running in don't ask mode.` Read literally, it means that one command was refused, not Bash as a whole.

Both share one thing: the command **never ran**, so do not wait for it to finish.

- The most common cause of a permission denial is a search command that omits its mandated exclusions for secret-bearing files (`.env`, `.database`, `.claude`). A Bash command naming a directory (`find <dir>`, `grep -r ... <dir>`, `cd <dir> && ...`) is modelled as a read of everything under it; without the exclusions it cannot be proven that a secret-bearing path will not be read, so the call escalates, and under `dontAsk` an escalation comes back as a denial rather than a prompt. A `find` over a work tree containing a `.claude` directory, run without the mandated exclusions, is denied this way, while the same command scoped to a subtree with no secret-bearing file runs.
- One command can get a hook denial when run in the foreground (named hook, stated fix) and a permission denial when run in the background (naming neither). These are two different denial shapes, not one broken session. This differs from averaging two hook denials into one theory: one denial is a hook and the other is not.
- Identify which part of the command is being modelled as a broad read, narrow or exclude it, and retry, as the next section requires.

### A `dontAsk` Denial Refuses One Command, Not Bash (MANDATORY)

A `dontAsk` permission denial refuses only the one command it names. The message says "Permission to use Bash", but its scope is that single call: the command text did not match an allow rule, so it escalated, and under `dontAsk` the escalation came back as a denial. Bash stays available, and the next call is judged on its own text.

Never stop the session, report that "Bash is disabled", or treat the task as blocked because of a permission denial. It does not meet the bar for stopping because the environment is too broken to work in, because nothing in the environment changed; only that command's shape was refused. Instead:

- **P1.** Rewrite the command in its rule-compliant form and retry it at once, in the same turn. Each of these shapes escalates for the same reason as a search without its exclusions: the permission system cannot prove what the call will touch from its text alone.
  - `git -C <dir> <command>`, not `cd <dir>; git <command>` or `cd <dir> && git <command>`.
  - Literal values, not `$VAR` or any other shell expansion, because an allow rule matches the text as written and cannot see what a variable expands to.
  - One simple command per call, not a `;` or `&&` chain, because every part of a chain must match an allow rule on its own and one unmatched part denies the whole call; make separate tool calls instead.
  - The mandated exclusions for secret-bearing files on every search.
- **P2.** Only if the rule-compliant form is also denied, log it as the next section describes, then carry on with the rest of the task.

### Logging an Allowlist Request (MANDATORY)

A rule-compliant command that the permission system still denies needs a new allow rule, which only the owner can add. Record it where the owner collects these requests, so the need is not lost when the session ends:

- **P1.** Check whether credfeto/credfeto-orchestrator#1167 already lists the same command, or an allow rule that would cover it. Reading comment bodies is not available yet, so until it is, go straight to P2; a duplicate request is harmless.
- **P2.** Otherwise, comment on credfeto/credfeto-orchestrator#1167 (`cfwf comment add --repo credfeto/credfeto-orchestrator --issue 1167 --body-file <file|->`) with the exact denied command, why the task needs it, and the repository the session is working in. Pass the multi-line body on stdin with a HEREDOC (or from a file) so real newlines are embedded, never escaped `\n` sequences.
- **P3.** Continue with the rest of the task. The request is for the owner to act on later; it does not block the current work.

## Background Tasks and Monitor Tool (MANDATORY)

A long command runs with `run_in_background: true`. The role then waits for the harness's background-task completion notification and judges pass or fail only by the exit code that notification reports. It never uses the `Monitor` tool or a poll loop to wait for a command, because a poll condition that can never be met loops for ever and blocks the session, and the only reliable signal that a command has finished is the harness's own notification.

### Finishing Background Work Before Handing Back

- **P1.** A role waits for the completion notification of each background command it started (a build, a test run, `pre-commit-check`, or a commit or push that runs hooks) and judges the command only by the exit code the notification reports: 0 is a pass and anything else is a failure. It never matches text the command prints, either to decide that the command has finished or that it succeeded, and never polls the command's output file for any text, including the harness's own `[exited with code N]` line, because test runners and hooks print whatever they like (`bats` prints TAP, for example), and waiting for a string the command never prints never ends. Reading the output once the notification has arrived, to find the cause of a failure, is fine.
- **P2.** A sub-agent may end its turn while a background command it started is still running, because the harness holds the sub-agent and wakes it once when the command finishes, with the command's exit code. It never reports or hands back while the command is still running, because its report would describe a result it has not seen. The main session of an unattended `-p` run must not end its turn while such a command is running, because ending its turn ends the run and can leave the command killed before it finishes, leaving the half-done state P3 describes.
- **P3.** A role never stops a background command it started with `TaskStop`, except for the deadline use in P4, because the command must finish and clean up after itself, and killing it can leave a stale `.git/index.lock`, partial build output or a push in an unknown state. Nothing in the harness bounds how long a command runs, so the 30-minute deadline is enforced by the main session instead, as the rules for waiting below describe.
- **P4.** `TaskStop` has only these uses:
  - the main session stopping a command that has overrun the 30-minute deadline;
  - the Orchestrator stopping a sub-agent that has already delivered its final report and is only repeating it.

## Never Truncate These Commands (MANDATORY)

`git commit`/`pre-commit`/`pre-commit-check`, `dotnet build`, `dotnet test`, `npm test`, and `bun test` have no bounded, predictable duration: `pre-commit` (and `pre-commit-check`, a wrapper that runs it against the existing checked-out repo) can run a heavy hook chain, `dotnet build` runs through a large analyzer stack plus package restore, and test runs scale with what changed. There is no timeout value that is both practical and safe to pick for any of these commands, so do not try to pick one.

- **Run only one of these commands at a time**; see One Long-Running Command at a Time below.
- **Always run these commands via `run_in_background`; never in the foreground, regardless of how fast the specific run is expected to be.** This is unconditional, not a per-invocation judgement call.
- **Never wrap any of these in a shell `timeout` command as a substitute or a belt-and-braces addition** (e.g. `timeout 590 dotnet test ...`), whether or not `run_in_background: true` is also set. `timeout` is on the categorical blocklist of the `reject-obfuscated-commands` hook and is rejected outright, independently of the backgrounding rule: plain `run_in_background: true` on the unwrapped command is already unbounded and needs no additional wrapper. A missing `run_in_background` and a banned `timeout` wrapper are denied by different hooks and are unrelated; read which hook actually fired rather than assuming a single general conflict.
- Wait for the harness's completion notification and judge the command only by the exit code it reports, subject to the same 30-minute deadline. Backgrounding these commands is not exempt from that deadline; it replaces a short, unsafe foreground cutoff with one deadline that the main session enforces.
- **A long stretch with no new output is normal and is not a hang.** Do not interpret silence as a failure and manually cancel or kill the command on that basis. Never stop waiting for the completion notification; only the main session stops a command, and only at the 30-minute deadline.
- A foreground command that reaches the tool's timeout is moved to the background, not killed. Wait for its completion notification as for any other background command.
- A killed run does not just fail; it skips the target process's own cleanup (a bash `EXIT` trap, .NET's `IDisposable` teardown, etc.), leaving orphaned temp directories, lock files, or half-applied state behind. Orphaned temp directories under a shared path can break other tools that walk the same path.
- Other `dotnet` commands (`dotnet restore`, a standalone `dotnet buildcheck`, `dotnet format`, etc.) are not covered by this unconditional rule; they may run in the foreground, but **always with an explicit maximum timeout set on the tool call**, never the tool's built-in default (e.g. Claude Code's Bash tool defaults to 2 minutes when no `timeout` is given; use the maximum available, e.g. 600000ms/10 minutes, explicitly). If even that maximum is not enough, use `run_in_background` and wait for the completion notification instead of accepting a truncated run.

### One Long-Running Command at a Time (MANDATORY)

- **P1.** A role never starts a long-running command while another long-running command it started is still running: it waits for the first command's completion notification before starting the next. "Long-running" means every command named in the Never Truncate These Commands section above (`git commit`/`pre-commit`/`pre-commit-check`, `dotnet build`, `dotnet test`, `npm test`, `bun test`) plus any other build, test or lint run started with `run_in_background` (for example `bats test/`). The CI Monitor role's `cfwf pr checks-wait` command is not a long-running command for this rule, because it only reads check status from GitHub and uses almost no memory. This is because each of these commands can use most of a small host's memory, and two at once can get the whole session OOM-killed, losing every in-flight task.
- **P2.** The rule applies across the whole session, not only within one role: the Orchestrator never has two roles running long-running commands at the same time, and never starts its own long-running command while a role it launched is running one.
- **P3.** A role that must run several checks (for example `pre-commit-check` and then `bats test/`) runs them one after another, never in parallel, each waiting for the previous one's completion notification.
- **P4.** Running two unbounded commands (build, test suite, `pre-commit-check`, commit) at the same time is never allowed; run them one after another.

## Rules for Waiting (MANDATORY)

- **P1.** **Prefer foreground for quick, bounded commands** (`git status`, a single `grep`, `ls`, and similar). **Always background project build/test/commit tooling instead** (`git commit`/`pre-commit`/`pre-commit-check`, `dotnet build`, `dotnet test`, `npm test`, `bun test`), regardless of how fast a specific run is expected to be, and run only one at a time. Use `run_in_background: true` for any other command that genuinely takes many minutes (e.g. a full integration-test run) and you have independent work to do while waiting.
- **P2.** **Time-box every background command to 30 minutes.** Nothing in the harness bounds how long a command runs, so the main session enforces the deadline: when it starts a long command itself, or launches a role that will, it schedules a wake-up (`ScheduleWakeup`) for 30 minutes later. `ScheduleWakeup` is not available inside sub-agents, so a sub-agent never enforces the deadline itself. If the command, or the role, has not finished when the wake-up fires, the main session reports the overrun:

  - In an interactive session, tell the human which command is still running and for how long.
  - In an unattended run, post the same as a comment on the work item, without the `Blocked` label, because the work is still in progress rather than waiting on a human:

    ```bash
    cfwf comment add --repo <owner/repo> --issue <number> --body-file - <<'COMMENT'
    Still running after 30 minutes: <what>; stopping it at the deadline.
    COMMENT
    ```

    Use `--pr <number>` instead of `--issue` if the work item is a PR.

  Then the main session stops the overrunning command with `TaskStop`, never the role that started it. The role wakes with the command's non-zero exit code and reports that the command was stopped at the deadline, so the failure is handled like any other.

  The CI Monitor role's `cfwf pr checks-wait` command needs no such wake-up and is never stopped, because it ends at its own `--timeout-minutes` limit and only reads.

## Sandbox-Caused False Timeouts in Benchmark/Perf Tests (MANDATORY)

If a `dotnet test`/`dotnet build` run that includes a benchmark or performance-test project fails with a timeout-shaped error (e.g. "configured timeout ... reached", "command took longer than the timeout", "Failed to set up high priority (Permission denied)"), do not conclude this is a genuine pre-existing or environmental limitation in the codebase before ruling out your own execution sandbox as the cause:

- **P1.** Re-run the identical command with sandboxing disabled if your tool supports it (e.g. a `dangerouslyDisableSandbox`-style flag).
- **P2.** Reproducing the same failure on a clean `main`/base branch does **not** rule out the sandbox; if you're still running inside the same sandboxed shell, that reproduction is confounded and proves nothing about the codebase itself.
- **P3.** If the failure disappears or measurably improves with sandboxing disabled, the sandbox was throttling CPU/resources; report this plainly; do not describe the benchmark suite as broken or flaky.
- **P4.** If still uncertain after disabling sandboxing, say so explicitly and ask the user to run the identical command in their own terminal before asserting any diagnosis; never present a sandbox artifact as a confirmed pre-existing bug.
