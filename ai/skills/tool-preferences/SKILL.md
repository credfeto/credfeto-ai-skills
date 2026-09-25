---
name: credfeto-tool-preferences
description: Choose the right tool or command when more than one could technically do the job, before making the call, not after a hook denial. Use whenever about to list files by a name/path pattern inside the workspace, run a repository-wide search or directory listing that could read secret-bearing files, fetch content that lives on GitHub (a file, PR, issue, diff, commit, release, or repo metadata), or otherwise choose between a built-in agent tool and an equivalent shell command. Distinct from interpreting a hook denial after the fact, which the claude-hooks skill covers.
---

# Tool Preferences

This skill covers which tool to reach for when more than one could technically do the job - a
built-in agent tool over an equivalent Bash command, or one Bash command over another. This is the
choice made *before* a tool call happens; it is distinct from the claude-hooks skill, which covers
how to interpret a hook *denial* once a call has already been made.

## Prefer Glob Over find for Simple File Listing (MANDATORY)

Use a `Glob`-style tool, not `find`, to list files matching a name/path pattern inside the
workspace - it is read-only by construction, always available, and does not go through the
Bash-command hook chain at all. Reach for `find` only when the need is something `Glob` cannot
express:

- Ownership/permission predicates (`-user`, `-group`, `-perm`)
- Time predicates (`-mtime`, `-newer`)
- `-exec`

## Exclude Secret-Bearing Files From Repo Searches (MANDATORY)

`.env`, `.env.*`, `*.env`, `.database`, any `.claude/` directory, and any file local instructions
mark as secret-bearing hold credentials or private configuration. Never let a repository-wide
search read them, whether via a shell command or a built-in tool:

- `grep`/`rg`: add `--exclude='.env' --exclude='.env.*' --exclude='*.env' --exclude='.database' --exclude-dir='.claude'`
  (rg: `-g '!.env*' -g '!*.env' -g '!.database' -g '!.claude/'`).
- `find`: add `-not -path '*/.claude/*' -not -name '.env*' -not -name '*.env' -not -name '.database'`.
- A `Glob`/`Grep`-style tool: use a pattern that cannot match them, or filter the result before
  reading any file.
- Never read or print one of these files; if a value from it is genuinely needed, ask the user
  to run the command themselves.

The pre-execution deny hooks are the backstop for this rule, not the first line of defence: a
denied search means the command was written wrongly, not that the hook is over-strict.

## Prefer `gh` or a Local Clone Over Fetching GitHub URLs (MANDATORY)

When looking up content that lives on GitHub - a file, PR, issue, diff, commit, release, or repo
metadata - do not fetch a `github.com`, `raw.githubusercontent.com`, or other
`*.githubusercontent.com` URL (e.g. via a web-fetch tool). Instead:

- If the repo is already cloned locally, read the file directly (e.g. a `Read`/`Glob`/`Grep`-style
  tool) rather than going over the network at all.
- Otherwise, use the appropriate `gh` subcommand (`gh api`, `gh pr view`, `gh issue view`,
  `gh repo view`, etc.).

This keeps lookups authenticated, respects any configured host proxy, and avoids relying on
public URL access the account may not actually have.
