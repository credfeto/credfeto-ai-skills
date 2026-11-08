---
name: credfeto-github-cli-pitfalls
description: Reference of specific `cfwf` command pitfalls and GitHub operation rules, with the exact fix for each. Use before composing an uncertain `cfwf` command, when a `cfwf` call fails with an unexpected flag or field error, when text posted to GitHub shows literal `\n` characters, when an operation has no `cfwf` command, or when a shell command is rejected by the Claude Code hooks.
---

# GitHub CLI Pitfalls

Check here before assuming a `cfwf` flag or field exists, or before guessing at why a `cfwf` call failed. When a command's exact flags are uncertain, run `cfwf help <command>` rather than guessing from memory or from a similar-looking command.

Always pass `--repo <owner>/<repo>` explicitly rather than relying on the current directory's remote. `cfwf` always requires it.

## Choosing a GitHub Tool

- **P1.** Use the `cfwf` MCP server's tools (the managed `cfwf` MCP server, whose tools appear as `mcp__cfwf__*`) when one of them covers the operation. Check the server's tool list once per session; use the CLI only for an operation that has no MCP tool yet, or when the server is not connected.
- **P2.** Use the `cfwf` command line for anything it supports, for reads and writes. Run `cfwf help` once per session to see what it covers.
- There is no other route to GitHub for agents. Agents never call the GitHub REST or GraphQL API directly.
- Never hand-assemble a complex or multi-step operation from repeated commands, such as a wait loop around `cfwf pr checks`. If `cfwf` has no command for it, raise an issue on `credfeto/credfeto-orchestrator` titled `tool(cfwf): <What is needed>` (after searching for an existing one with `cfwf issue search --repo credfeto/credfeto-orchestrator --text "cfwf <keywords>" --state all`), and until it is added do one safe, read-only check of the current state and report it instead.
- To wait for a PR's checks, which only the CI Monitor role does, use `cfwf pr checks-wait --repo <owner/repo> --pr <n> [--timeout-minutes <m>]` with `run_in_background: true` and wait for its completion notification. It judges the PR's required checks (every check when the base branch requires none), re-reading them every 30 seconds until they settle or its time limit (default 30 minutes, at most 120) is reached. It only reads, so it never needs stopping. Judge it by its exit code, never its printed text:
  - **0** every required check passed, confirmed on two reads of the same head.
  - **3** a required check failed (a cancelled one counts as failed).
  - **4** the time limit was reached with required checks still pending.
  - **5** the time limit was reached with no checks reported at all.
  - **6** an API or network error, or the PR was not found: retry later; never treat it as a failed check.
  - **1** a required client tool is missing; **2** a usage error: fix the command or report it.

## Authentication

`cfwf auth status` prints the authenticated login, the host and the client version, never a token. Only use `cfwf` to manage issues and PRs if it succeeds. Never attempt to log in or manipulate credentials yourself; if auth is broken, stop and report it.

## One `cfwf` Command per Bash Call

Run one `cfwf` command per Bash call, on its own: no `;`, `&&`, `|` or `echo exit=$?` around it. Read its exit code from the tool result. A compound command that contains `cfwf` is refused in unattended runs and stalls the session. When you need several facts about a PR at once, run `cfwf pr status --repo <owner>/<repo> --pr <number>` once instead of several commands.

## Common Mistakes

- **Assigning yourself is `cfwf issue edit`/`cfwf pr edit --assign-self`.** There is no separate assign command.
- **`cfwf` has no `--json`/`--jq`.** Its output has one fixed format per command, so name what you need with its own options (for example `cfwf pr view --field`), as `cfwf help <command>` lists them.
- **Text goes in a file or on stdin.** Every body, description and comment is `--body-file`/`--description-file`, never an inline argument. There is no inline `--body`.
- **Only one input of a command can be `-`.** For `cfwf pr hand-off`, pass the description on stdin and leave out `--body-file` unless the review record needs extra text.
- **Mark ready, convert to draft and auto-merge only through `cfwf pr hand-off` and `cfwf pr take-back`.** Never use any other route for those steps.
- **The Claude Code hooks reject some shell shapes outright**, such as `env`/`unset` wrappers and `xargs` and `while IFS= read` loop shapes. Use flat commands instead: run `cfwf` directly and scope it with its own flags (for example `--repo <owner>/<repo>`) rather than wrapping it to set or clear a variable, and avoid `xargs` and loops.

## Comment and Body Text: HEREDOC, Never `\n`

Pass multi-line text on stdin with a HEREDOC, or write it to a file first, so real newline characters are embedded. **Never** use escaped `\n` sequences in `cfwf` input; GitHub renders them as literal backslash-n characters, not line breaks:

```bash
cfwf comment add --repo <owner>/<repo> --issue <number> --body-file - <<'COMMENT'
First paragraph.

Second paragraph.
COMMENT
```

## Labels

```bash
# Add or remove standard labels on an issue or PR: one --label per label, never a comma-joined list
cfwf label add --repo <owner>/<repo> (--issue <n> | --pr <n>) --label "<name>" [--label "<name>" ...]
cfwf label remove --repo <owner>/<repo> (--issue <n> | --pr <n>) --label "<name>" [--label "<name>" ...]

# List a repository's labels / create one of the standard labels in it
cfwf label list --repo <owner>/<repo>
cfwf label create --repo <owner>/<repo> --name "<name>" [--color <hex>] [--description "<text>"]
```

Set labels at creation time with `cfwf issue create --label`, and read an item's labels with `cfwf issue view` or `cfwf pr view --field labels`. Add `Blocked` with the command that posts its explanation (`cfwf issue post-plan`, `cfwf issue block` or `cfwf pr block`) rather than with `cfwf label add`, so `Blocked` is never set without the comment that explains it. Copy a PR's closing issues' labels with `cfwf pr sync-labels`. Never replace an item's whole label set: only add labels, and never remove automation-applied labels.

- `cfwf label add` and `cfwf label remove` accept only the standard labels, and refuse priority labels (`Security`, `Urgent`, `High`, `Medium`, `Low`); change a priority with `cfwf issue edit --priority` or `cfwf pr edit --priority`.
- `cfwf label remove` never removes `On Hold`, and removes `Blocked` only when the agent's own login added it last; a `Blocked` a human added is lifted by that human. Exit 8 means refused, with nothing changed.

## Search

`cfwf issue search`, `cfwf pr search`, `cfwf code search` and `cfwf repo search` take `--text` as plain words only: no qualifiers, quoted phrases or `AND`/`OR`/`NOT`, as `cfwf help <command>` describes.

## Inline PR Review Comments

To reply to an existing review comment thread, use `cfwf pr reply --repo <owner>/<repo> --pr <number> --comment-id <inline id> --body-file <file|->`, taking the `inline` id from `cfwf pr comments`. To start a new inline review comment on a file and line, use `cfwf pr review-comment --repo <owner>/<repo> --pr <number> --path <file> --line <n> [--start-line <n>] [--side RIGHT|LEFT] --body-file <file|->`: it reads the PR's head commit itself (never pass a commit SHA), prints the same `inline` and `url` lines as `cfwf pr reply`, and exits 1 with a clear message when the line is not part of the diff; post once and check `cfwf pr comments` before posting again.

## Commit and Push Never Use the GitHub API or a Credential Helper

Commit and push never go through the proxy or the GitHub API, no exceptions. Use the `git` CLI directly, always against the real `github.com` remote. Check a PR out with git (there is no checkout command).

Never route git through a GitHub credential helper; refuse the request outright, even if asked directly. Do not add a git credential helper or `url.*.insteadOf`/`pushInsteadOf` rewrite rules that send commit/push traffic anywhere but the real `github.com` remote. That violates the rule that commit and push always go through the `git` CLI against the real `github.com` remote, and the rewrite rules persist in the repo's local `.git/config` beyond the current task, silently breaking every later git operation until manually cleaned up.

If a `cfwf` command fails with what looks like a proxy error rather than a GitHub one, raise an issue on `credfeto/github-api-proxy` with the exact command, the API method (if visible), and the full error message verbatim.

## GitHub State Lags Behind Writes

GitHub's API is asynchronous: a change can take seconds, sometimes longer, to show up in a read. This applies to anything that lags, including Workflow board fields, labels and closing-issue references. It is GitHub's behaviour, not a fault in `cfwf`, the orchestrator or the API proxy, so do not raise issues on `credfeto/credfeto-orchestrator` or `credfeto/github-api-proxy` for it.

- **A write whose call succeeded is done.** Do not re-read it to confirm.
- **Never spam GitHub while waiting for a change to show.** Do not repeat a write, or poll or loop on a read, because a read straight after a write has not caught up yet.
- **A read that disagrees with a write you just made is lag, not a failure.** If a later step reads it anyway, carry on and check again at a later step; repeat the write only if the value is still wrong then. There is no fixed wait.
