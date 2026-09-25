---
name: credfeto-claude-hooks
description: Interpret a Claude Code PreToolUse hook denial correctly when a Bash tool call is blocked before it runs, and tell it apart from a denial coming from Claude Code's separate permission system. Use whenever a tool call is rejected/blocked/denied by a pre-execution policy hook or by the permission system, whenever a git, dotnet, or other shell command fails with a denial-shaped message instead of normal command output, or when deciding whether to poll for a command's completion versus fix-and-retry it immediately.
---

# Claude Code Hook Interaction

A fixed set of Claude Code `PreToolUse` hooks may run against every Bash tool call in the current
environment; a couple also match a specific non-Bash tool call. This skill covers how to interpret
a hook **denial** correctly, and how to tell one apart from a denial coming from Claude Code's
separate permission system. For how to background and poll a long-running command once a call has
actually been **accepted**, see the long-running-commands skill instead; this skill is about the
different, earlier case where the call was rejected before it ever started.

## A Denial Means the Command Never Ran (MANDATORY)

A `PreToolUse` hook denial (a tool result explaining the call was blocked) means the command
**never started**. There is nothing in flight and nothing will ever notify you about it later.

- Fix the specific thing the denial names and retry **immediately, in the same turn**.
- Never end a turn saying you are "waiting for it to finish" or "waiting for a completion
  notification" for a denied command. This matters most acutely in a single-shot session: there
  is no later turn for that notification to land in, so uncommitted work is silently abandoned,
  but the same misread is just as wrong in an interactive session with turns to spare.

## Read the Denial's Stated Reason Literally (MANDATORY)

What "the specific thing" above means in practice:

- `git commands must use "git -C <dir>" format` means add `-C <dir>` to that git invocation, not a
  general git problem.
- `git commit must run with run_in_background: true` means add that tool parameter, not switch to
  a different commit approach.

Fixing one hook's violation at a time and retrying can trigger a second hook's denial on the same
call, so satisfy every applicable rule in the one call that is retried rather than discovering them
one by one. The most common case is a command that must satisfy both a git-invocation-shape hook
and a must-be-backgrounded hook at once: `git -C <dir> commit -m "..."` invoked with
`run_in_background: true` set on that same tool call.

Different denials on similar-looking commands usually come from **different** hooks with
**different** fixes; do not average them into one general theory (e.g. "backgrounding is broken").
Read the exact hook name and message each time. For example, a plain `dotnet test` without
`run_in_background: true` is blocked by a background-enforcement hook, while the same command with
both `run_in_background: true` *and* a `timeout N` shell wrapper is blocked by an
obfuscated-command/wrapper-command policy hook instead (`timeout` is categorically blocklisted, see
the reference table below): a wrapper-command rejection, unrelated to backgrounding. These are two
independent, correctly-working checks, not one contradiction.

## A Permission Denial Is Not a Hook Denial (MANDATORY)

Claude Code has a second way to refuse a command: the permission system itself, sitting above the
hook chain. Under a "don't ask" permission mode, a command that would normally prompt for approval
is auto-denied instead. This is not a `PreToolUse` hook running; no hook name appears anywhere in
the message.

Tell the two apart by the message shape, not by guessing at a cause:

- A **hook** denial names the hook and states a reason and a fix, in the shared form every hook
  uses: `Blocked (command did not run - fix and retry, do not wait for it): <reason>`.
- A **permission** denial names no hook, states no rule, and gives no fix, typically just
  `Permission to use Bash has been denied because Claude Code is running in don't ask mode.`

The one thing both share: the command **never ran**. Everything in
[A Denial Means the Command Never Ran](#a-denial-means-the-command-never-ran-mandatory) above
applies identically to a permission denial; do not wait for it to finish.

The most common cause of a permission denial is a search command that omits its mandated
exclusions. A Bash command naming a directory (`find <dir>`, `grep -r ... <dir>`, `cd <dir> && ...`)
is modelled as a read of everything under it. Without excluding secret-bearing paths such as
`.env`/`.env.*`/`*.env`/`.database`/`.claude/` (see the tool-preferences skill for the exact
exclusion flags), it cannot be proven that one of them will not be read, so the call escalates, and
under a "don't ask" permission mode an escalation comes back as a denial rather than a prompt.

Confirmed in practice: a `find` over a work tree containing a `.claude` directory, run without the
mandated exclusions, was denied this way, message-for-message; the identical command scoped to a
subtree with no secret-bearing file ran clean. This is also a live, more general risk: an agent
working an unrelated issue in another repository hit both denial shapes on the same underlying
command (`pre-commit-check`), a genuine hook denial in the foreground (named hook, stated fix) and a
permission denial in the background (naming neither), read the two as one broken session rather
than two different denial shapes, and escalated to a human on the first occurrence. This differs
from averaging two hook denials into one theory: here, one denial was a hook and the other wasn't.
Identify which part of the command is being modelled as a broad read, narrow or exclude it, and
retry before escalating to a human.

## Prefer the Tool's Own Backgrounding Parameter (MANDATORY)

Use the tool's own `run_in_background: true` parameter, never shell-level backgrounding (`&`,
`nohup ... &`, `disown`). Shell-level backgrounding is commonly blocked outright by a
background-enforcement hook and produces the same denial-misread-as-in-flight failure described
above.

## Reference: Installed Hook Set

A typical installed hook set blocks along these lines, in roughly the order the hooks run (the exact
set, its rationale, and any ordering is documented in each hook's own header comment; treat the
summary below as illustrative and possibly stale rather than authoritative, and read the live hook
config on the container when a denial's cause is unclear):

| Hook | Blocks | Why |
| --- | --- | --- |
| `reject-obfuscated-commands` | Any Bash command not built from plain, obviously-spelled command words (indirect execution, sub-shells, wrapper-flag smuggling) | Text/regex scanning for banned patterns is an arms race that never converges against a determined bypass attempt; parsing with a real shell parser and applying policy to the resulting AST closes that gap. Reads `command-allowlist`, `command-blocklist`, and `env-var-blocklist` as its data tables. |
| `command-allowlist` (data file, not a hook) | N/A | Known-good command names for `reject-obfuscated-commands`; a command not on this list (and not on `command-blocklist`, which wins) is rejected outright. |
| `command-blocklist` (data file, not a hook) | N/A | Known-bad command names for `reject-obfuscated-commands` (e.g. `eval`, `source`, `bash`, and wrapper commands including `timeout` and `xargs`) that are rejected even though they are plain bare words, because each one hides or re-enters execution in a way this check cannot see through, or (for the wrapper commands) can smuggle another command past name-based checks. This is why a shell `timeout` wrapper around `dotnet test`/`dotnet build`/`git commit` is always rejected, backgrounded or not; see the long-running-commands skill. |
| `env-var-blocklist` (data file, not a hook) | N/A | Environment variables (`PATH`, `IFS`, `LD_PRELOAD`, `GIT_*`, and similar) that `reject-obfuscated-commands` refuses to let a command assign, because they change how *other* commands are located, parsed, or attributed. |
| `enforce-allowed-dirs` | `cd`/`pushd`, `git -C`, `npm --prefix`, `find` starting points, and `rm`/`mv`/`cp` operands outside a configured allowlist of directory roots, plus flags on those same commands that turn a path argument into code execution (`git --exec-path`/`--git-dir`/`--work-tree`, most `git -c` keys, `npm --script-shell`, `find -exec`/`-delete`, `rm --no-preserve-root`) | The permission-rule syntax has no typed placeholder for "a directory goes here", so a wildcarded directory position also matches any option injected there; this hook does the positional check statically instead. A directory outside every configured allowed root blocks. |
| `block-no-verify` | `--no-verify`/`-n` on any git command that would skip commit hooks, and the equivalent on a GitHub-tool call | Enforces "never bypass hooks or formatters": a failing pre-commit hook must be fixed and retried, not skipped. |
| `enforce-git-identity` | Git subcommands that create or rewrite commits (or precede one, like `fetch`) unless git identity and GPG signing are correctly configured | Prevents an unsigned or misattributed commit from being created at all, rather than relying on review to catch it afterwards. |
| `enforce-git-dash-c` | Any git subcommand not written as `git -C <dir> <command>` | Keeps git operations explicit about which working tree they target instead of relying on the shell's current directory. |
| `block-git-worktree` | `git worktree add`, and the equivalent native worktree-creation tool call | Worktrees split repo state across multiple linked checkouts sharing one object store; tooling that assumes a single checkout per repo directory can be left with a bare primary checkout by an errant `worktree add`. |
| `block-dotnet-tool-install` | `dotnet tool install` (local or global) and `dotnet new tool-manifest` | Global .NET tools are pinned and baked into the image at build time; installing an unpinned tool at runtime would bypass the dependency-selection review the pinned set went through. |
| `enforce-ssh-host-and-key` | Any `ssh` call other than exactly `ssh user@host command...` with no flags, and one when no usable key is loaded in the forwarded ssh-agent | `ssh` has a blanket allow entry; the danger is in the destination, not the verb, which a permission-rule prefix pattern cannot scope. Restricts the host to a private-network suffix and requires the agent to hold a working key first, since the container never mounts raw private key files. |
| `enforce-background-for-long-running-commands` | `git commit`, `pre-commit` (direct invocation), `pre-commit-check` (a wrapper around it), `dotnet build`, `dotnet test`, `npm test`, and `bun test` unless the call sets `run_in_background: true` | See the long-running-commands skill for why none of these have a safe foreground timeout. |
| `cache-gh-lookups` | Nothing; it never blocks | Rewrites a bare `gh api user --jq '.login'` call to read a cached copy instead of hitting the API every time, falling through unchanged on any parse failure. |

If a command is blocked by a hook not listed here, or this table no longer matches the live hook
configuration, treat the table as stale rather than the denial as wrong: read the hook's own header
comment (each one documents its rationale) before assuming it is a bug.
