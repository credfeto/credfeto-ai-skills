---
name: credfeto-shell-scripts
description: Write standalone shell scripts that pass shellcheck/checkbashisms, use consistent die/success/info output helpers, and detect AI-agent invocation correctly. Use whenever creating or modifying a .sh file, or any standalone shell script work.
---

# Shell Script Conventions

## Shebang

- Prefer `#!/bin/sh`; only use `#!/bin/bash` if bash-specific functionality is genuinely required.
- All `#!/bin/sh` scripts must pass `shellcheck` and `checkbashisms` before committing.

## Output Helpers (MANDATORY)

Use `die`, `success`, and `info` for all user-facing output in standalone shell scripts: never bare `echo` or `printf`. This applies to standalone shell scripts only; GitHub Actions `run:` steps use emoji indicators instead.

```sh
die() {
    if [ -t 2 ]; then
        printf '\n\033[31m✗\033[0m %s\n' "$*" >&2
    else
        printf '\n✗ %s\n' "$*" >&2
    fi
    exit 1
}

success() {
    if [ -t 1 ]; then
        printf '\n\033[32m✓\033[0m %s\n' "$*"
    else
        printf '\n✓ %s\n' "$*"
    fi
}

info() {
    if [ -t 1 ]; then
        printf '\n\033[32m→\033[0m %s\n' "$*"
    else
        printf '\n→ %s\n' "$*"
    fi
}
```

- `die`: fatal error, red `✗` to stderr, exits non-zero.
- `success`: completion, green `✓`.
- `info`: progress/step announcement, green `→`.
- Always direct `die()` to stderr (`>&2`) so error messages are not captured by stdout pipelines.
- Use `"$*"` to pass the message as a single string (required for `shellcheck` and `checkbashisms` compliance).
- The `[ -t N ]` guards suppress ANSI codes when output is piped to a file, which lets tools like `grep` match the plain `→` and `✓` characters without escape sequences.

### Usage Example

```sh
info "Opening port ${PORT}/tcp..."   # correct: uses helper
printf '→ Opening port %s/tcp...\n' "${PORT}"  # wrong: naked printf
```

## AI Agent Detection

Scripts that behave differently when invoked by an AI agent must use the standard `is_ai_agent` helper:

```sh
# Returns true (0) when running inside a Claude Code Bash-tool session.
# Claude Code sets CLAUDECODE=1 in every shell it spawns via the Bash tool;
# that value is inherited by subprocesses (e.g. git hooks).
# Source: https://docs.anthropic.com/en/docs/claude-code/settings#environment-variables
is_ai_agent() {
    [ "${CLAUDECODE}" = "1" ]
}
```

Usage:

```sh
if is_ai_agent; then
    die "Prohibited: did you read the .ai-instructions?"
else
    die "Normal human-facing error message"
fi
```

Define `is_ai_agent` alongside the other output helpers near the top of the script, not inline at the point of use. Always keep the source URL comment.

## Git File Lists

Read git file lists NUL-separated:

- In a committed script or workflow step whose per-file work is a single fixed command, pipe the list to `xargs -0r`, for example `git ls-files -z -- '*.sh' | xargs -0r shellcheck --`, with a pathspec so the command only sees the files it applies to; `-r` skips the run when the list is empty. This is the preferred form in `#!/bin/sh` scripts.
- Agents must never use `xargs` or the `while IFS= read` loops below in their own ad-hoc shell commands: `xargs` is on the `command-blocklist` and the agent sandbox rejects the loops. Neither restriction applies to committed scripts or workflow steps.
- Where the per-file work is shell logic rather than a single command, make the script `#!/bin/bash` and loop with `while IFS= read -r -d '' f; do ...; done < <(git ls-files -z)`, because process substitution is bash-only and fails `checkbashisms`. Use `mapfile -d '' files < <(git ls-files -z)` only where bash 4.4 or later is guaranteed, because `mapfile -d` needs bash 4.4 and macOS `/bin/bash` is 3.2.
- Only where such a script cannot be switched to bash, use `git ls-files -z | tr '\0' '\n' | while IFS= read -r f; do ...; done`. This splits a name containing a newline into two, and files from elsewhere may have such names, so use it only where they cannot occur; and the loop runs in a subshell, so variables it sets are lost after `done`.
- None of these forms surfaces a `git ls-files` failure (`#!/bin/sh` has no `pipefail`, so a pipeline returns the status of its last command, and bash discards a process substitution's exit status even under `set -e`). A failing git, for example one refusing a checkout with `detected dubious ownership`, yields an empty list and the script exits 0 having checked nothing. Where an empty list would silently pass, run git on its own first and check its status, for example `git ls-files -z >"$tmp" || die "git ls-files failed"`, then read the list from `"$tmp"`.

## Argument Size Limits

Never pass a value of unbounded or externally-sourced size (an API response, accumulated log/comment data, file contents, etc.) as a single command-line argument to an external command. Use stdin (piping), or a temp file with a flag designed for it (e.g. `jq --slurpfile`/`--rawfile` instead of `--argjson`/`--arg`), instead.

- This applies even when the total combined argument list looks well under `ARG_MAX`: a single argv string is separately capped at `MAX_ARG_STRLEN` (128KiB on Linux), and that per-string ceiling is the one that actually gets hit in practice with growing data.
- Values that are inherently small and bounded (flags, IDs, short fixed strings, scalars) are fine as regular arguments.
