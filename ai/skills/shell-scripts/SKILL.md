---
name: credfeto-shell-scripts
description: Write standalone shell scripts that pass shellcheck/checkbashisms, use consistent die/success/info output helpers, and detect AI-agent invocation correctly. Use whenever creating or modifying a .sh file, or any standalone shell script work.
---

# Shell Script Conventions

## Shebang

- Prefer `#!/bin/sh`; only use `#!/bin/bash` if bash-specific functionality is genuinely required.
- All `#!/bin/sh` scripts must pass `shellcheck` and `checkbashisms` before committing.

## Output Helpers (MANDATORY)

Use `die`, `success`, and `info` for all user-facing output in standalone shell scripts — never bare `echo` or `printf`. This applies to standalone shell scripts only; GitHub Actions `run:` steps use emoji indicators instead (`✅`/`❌`/`⚠️`/`ℹ️`).

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

- `die` — fatal error, red `✗` to stderr, exits non-zero.
- `success` — completion, green `✓`.
- `info` — progress/step announcement, green `→`.
- Always direct `die()` to stderr (`>&2`) so error messages are not captured by stdout pipelines.
- Use `"$*"` to pass the message as a single string (required for `shellcheck` and `checkbashisms` compliance).
- The `[ -t N ]` guards suppress ANSI codes when output is piped to a file, which lets tools like `grep` match the plain `→`/`✓`/`✗` characters without escape sequences.

### Usage Example

```sh
info "Opening port ${PORT}/tcp..."   # correct — uses helper
printf '→ Opening port %s/tcp...\n' "${PORT}"  # wrong — naked printf
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
    die "Prohibited — did you read the .ai-instructions?"
else
    die "Normal human-facing error message"
fi
```

Define `is_ai_agent` alongside the other output helpers near the top of the script, not inline at the point of use. Always keep the source URL comment.
