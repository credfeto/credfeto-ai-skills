---
name: credfeto-changelog
description: Add, remove, read, release or lint CHANGELOG.md entries using the changelog MCP server's tools, falling back to the dotnet changelog tool (Credfeto.Changelog.Cmd) only when the server cannot do the operation. Use whenever a change needs a changelog entry, before committing feature/fix work, when pushing a commit to a Dependabot or other bot-authored PR, or when acting as the Changelog agent. Never edit CHANGELOG.md by hand.
---

# Changelog Management

Never edit `CHANGELOG.md` manually; change it only through the changelog tooling below. A change made by a `changelog` MCP tool counts as the tool, not a hand edit.

## Tool Choice

- **Use the `changelog` MCP server's tools (`mcp__changelog__*`) first.** The server is `Credfeto.ChangeLog.Mcp` (command `changelog-mcp`), the MCP form of the `dotnet changelog` CLI. Use its tool for every changelog operation it lists, the same way the build-dotnet MCP tools are used for builds and tests.
- **Fall back to the `dotnet changelog` CLI only when the server is not connected, or is connected but does not list the tool the operation needs.** `Credfeto.Changelog.Cmd` is the dotnet tool package that provides the `dotnet changelog` command; no separate install step is required if the repo's dotnet tool manifest already includes it.
- **Never do one operation both ways.** Pick the MCP tool or the CLI for each operation, never run the same add, remove or other change through both, because the second run duplicates or undoes the first.
- Invoke the CLI as `dotnet changelog`; never search for the tool binary, add it to `PATH`, or invoke it directly as `~/.dotnet/tools/toolname` or similar.

## When to Skip

Do **not** add an entry if:

- The repository name contains `-template` (e.g. `credfeto/cs-template`), kept blank for template consumers. The Changelog agent's Placeholder step still commits a `.deleteme.now` file instead.

## Entry Content

Entries must describe **what changed and why it matters**, not how it was implemented.

## Dependabot and Other Bot PRs

- If you push any commit to a Dependabot (or other bot-authored) PR, taking ownership, rebasing, resolving conflicts, addressing review comments, later CI runs on that PR may no longer attribute `github.actor` to the bot. Some repos' changelog-check workflow (e.g. an `include-changelog-entry` job in `pr-lint.yml`) only skips the `CHANGELOG.md` diff check when `github.actor == 'dependabot[bot]'`, so the check can start failing even though the PR still carries a `Changelog Not Required` label from when the bot opened it.
- In that situation, if the repo's rules require a changelog entry, add one with the changelog tooling (the `changelog_add` MCP tool, or the CLI as the fallback) describing the change (e.g. the dependency bump) exactly as you would for any change you authored yourself. Do not rely on the pre-existing `Changelog Not Required` label once you have pushed to the PR; verify the CI check actually passes.
- This is a workaround for the actor-detection gap, not a substitute for fixing it. If you have write access to the workflow, also consider fixing the underlying check to key off `github.event.pull_request.user.login` instead of `github.actor`, so future bot PRs are not affected.

## Commands

Each operation has one MCP tool and one CLI fallback; use the CLI form only under the fallback rule above.

| Operation | MCP tool | CLI fallback |
| --------- | -------- | ------------ |
| Add an entry to `[Unreleased]` | `changelog_add` (`type`, `message`) | `dotnet changelog -f CHANGELOG.md -a <Type> -m "<message>"` |
| Remove an entry from `[Unreleased]` | `changelog_remove` (`type`, `message`) | `dotnet changelog -f CHANGELOG.md -r <Type> -m "<exact message to remove>"` |
| Read the `[Unreleased]` section | `changelog_unreleased` | `dotnet changelog -f CHANGELOG.md -u` |
| Extract a release's notes | `changelog_extract` (`version`) | `dotnet changelog -f CHANGELOG.md -v <version> -x <output file>` |
| Create a release from `[Unreleased]` | `changelog_create_release` (`version`, optional `pending`) | `dotnet changelog -f CHANGELOG.md -c <version>` (add `-p` for pending) |
| Check only `[Unreleased]` changed since a branch | `changelog_check_insert` (optional `branch`, default `origin/main`) | `dotnet changelog -f CHANGELOG.md -t origin/main` |
| Lint the changelog | `changelog_lint` (optional `fix`) | `dotnet changelog -f CHANGELOG.md -l` (add `--fix` to rewrite) |

Every MCP tool finds `CHANGELOG.md` automatically and takes an optional `changelog` path. For the CLI's full option list run `dotnet changelog --help`.

Valid types: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`, `Deployment Changes`

The CLI fallback is not covered by the rule that long test and commit commands run in the background, so it may run in the foreground, but always with an explicit maximum timeout set on the tool call (for example 600000ms), never the tool's built-in default. If even that maximum is not enough, run it in the background and wait for the completion notification instead of accepting a truncated run.

## Repository Requirements

- `CHANGELOG.md` must be listed in `.markdownlintignore` at the repo root (create the file if absent).
