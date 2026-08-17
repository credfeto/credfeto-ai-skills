---
name: credfeto-tool-preferences
description: Choose the right tool when more than one could technically do the job, before making the call, not after a hook denial. Use whenever about to list files by a name/path pattern inside the workspace, or otherwise choosing between a built-in agent tool and an equivalent shell command. Distinct from interpreting a hook denial after the fact, which the claude-hooks skill covers.
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
