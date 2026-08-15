---
name: credfeto-claude-hooks
description: Interpret a Claude Code PreToolUse hook denial correctly when a Bash tool call is blocked before it runs. Use whenever a tool call is rejected/blocked/denied by a pre-execution policy hook, whenever a git, dotnet, or other shell command fails with a denial-shaped message instead of normal command output, or when deciding whether to poll for a command's completion versus fix-and-retry it immediately.
---

# Claude Code Hook Interaction

A fixed set of Claude Code `PreToolUse` hooks may run against every Bash tool call in the current
environment. This skill covers how to interpret a hook **denial** correctly. For how to background
and poll a long-running command once a call has actually been **accepted**, see the
long-running-commands skill instead; this skill is about the different, earlier case where the
call was rejected before it ever started.

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

## Prefer the Tool's Own Backgrounding Parameter (MANDATORY)

Use the tool's own `run_in_background: true` parameter, never shell-level backgrounding (`&`,
`nohup ... &`, `disown`). Shell-level backgrounding is commonly blocked outright by a
background-enforcement hook and produces the same denial-misread-as-in-flight failure described
above.

## Reference: Installed Hook Set

A typical installed hook set blocks along these lines (the exact set and its rationale is
documented in each hook's own header comment; treat the summary below as illustrative and possibly
stale rather than authoritative, and read the live hook config on the container when a denial's
cause is unclear):

| Hook | Blocks | Why |
| --- | --- | --- |
| Obfuscated-command rejection | Any Bash command not built from plain, obviously-spelled command words (indirect execution, sub-shells, wrapper-flag smuggling) | Text/regex scanning for banned patterns is an arms race that never converges against a determined bypass attempt; parsing with a real shell parser and applying policy to the resulting AST closes that gap. Driven by allowlist/blocklist/env-var-blocklist data tables: a command not on the allowlist (and not on the blocklist, which wins) is rejected outright; blocklisted commands (e.g. `eval`, `source`, `bash`) are rejected even as plain bare words because each hides or re-enters execution in a way the check cannot see through; blocklisted environment variables (`PATH`, `IFS`, `LD_PRELOAD`, `GIT_*`, and similar) are refused because they change how *other* commands are located, parsed, or attributed. |
| Git directory-shape enforcement | Any git subcommand not written as `git -C <dir> <command>` | Keeps git operations explicit about which working tree they target instead of relying on the shell's current directory. |
| Git identity enforcement | Git subcommands that create or rewrite commits (or precede one, like `fetch`) unless git identity and GPG signing are correctly configured | Prevents an unsigned or misattributed commit from being created at all, rather than relying on review to catch it afterwards. |
| Background-enforcement for long-running commands | `git commit`, `pre-commit` (direct invocation), `dotnet build`, `dotnet test`, `npm test`, and `bun test` unless the call sets `run_in_background: true` | These commands have no safe, practical foreground timeout: `pre-commit` can run a heavy hook chain, `dotnet build` runs through a large analyzer stack plus package restore, and test runs scale with what changed. |
| Worktree blocking | `git worktree add` | Worktrees split repo state across multiple linked checkouts sharing one object store; tooling that assumes a single checkout per repo directory can be left with a bare primary checkout by an errant `worktree add`. |
| Tool-install blocking | `dotnet tool install` (local or global) and `dotnet new tool-manifest` | Global tools are pinned and baked into the image at build time; installing an unpinned tool at runtime would bypass the dependency-selection review the pinned set went through. |

If a command is blocked by a hook not listed here, or this table no longer matches the live hook
configuration, treat the table as stale rather than the denial as wrong: read the hook's own header
comment (each one documents its rationale) before assuming it is a bug.
