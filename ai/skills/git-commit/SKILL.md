---
name: credfeto-git-commit
description: Commit and push changes safely — identity/GPG verification, branch checks, build/test gates, Conventional Commits format, and push cadence. Use whenever about to commit, stage, or push changes in any repository, or when acting as the Committer agent.
---

# Git Commit Workflow

Follow every step below, in order, for every commit.

## 1. Build and Test Verification (MANDATORY)

Build must pass and all tests must pass before committing or pushing. If they fail and cannot be resolved, stop and ask.

## 2. Git Identity Check (MANDATORY)

Verify identity and GPG signing are correct before any commit:

```bash
#!/bin/sh
die() {
    printf '\n\033[31m✗\033[0m %s\n' "$*" >&2
    exit 1
}

info() {
    printf '\n\033[32m→\033[0m %s\n' "$*"
}

CURRENT_EMAIL=$(git config user.email)

[ -z "$CURRENT_EMAIL" ] && die "git user.email is not set — run: git config --global user.email \"you@example.com\""

[ "$(git config commit.gpgsign)" = "true" ] || die "GPG signing is not enabled — run: git config --global commit.gpgsign true"

command -v gpg > /dev/null 2>&1 || die "gpg is not installed — cannot verify signing key"

gpg --list-secret-keys "$CURRENT_EMAIL" > /dev/null 2>&1 \
    || die "no GPG secret key found for ${CURRENT_EMAIL} — run: gpg --gen-key"

SIGNING_KEY=$(git config user.signingkey)
[ -z "$SIGNING_KEY" ] && die "git user.signingkey is not set — run: git config --global user.signingkey <keyid>"

gpg --list-secret-keys "$SIGNING_KEY" > /dev/null 2>&1 \
    || die "git user.signingkey (${SIGNING_KEY}) not found in GPG keyring"

gpg --list-secret-keys "$SIGNING_KEY" 2>/dev/null | grep -qF "$CURRENT_EMAIL" \
    || die "git user.signingkey (${SIGNING_KEY}) is not associated with ${CURRENT_EMAIL}"

info "git identity check passed (${CURRENT_EMAIL}, key ${SIGNING_KEY})"
```

**If either check fails: stop all work, do not commit, and report the misconfiguration.**

## 3. Branch Check (MANDATORY)

- Run `git branch --show-current` and confirm it is the expected working branch before staging or committing.
- **Never commit if the current branch is `main`.**
- If the branch has switched to `main` and the upstream no longer exists (merged and deleted), create a new branch before continuing.

## 4. Commit Rules (MANDATORY)

- **Never create an empty commit.** Verify `git diff --cached --name-only` lists at least one file before running `git commit`.
- Never amend an existing commit — always create a new one.
- One logical change per commit; do not batch unrelated changes.
- **Never bypass hooks or formatters.** If they fail, stop and report the failure.
- **Never bypass commit message validation.** If it fails, stop and report the failure.
- **Never change linting or formatting rules to force a commit through.**
- **Never modify ignore files to force a commit through.**

### Unexpected reformatting during commit

If hooks or formatters modify files **not in your intended change set**:

1. Do not stage the unrequested changes.
2. Abort the commit.
3. Report the affected files and which hook/formatter changed them.
4. Wait for explicit instructions.

## 5. Commit Message Format

- Use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) format.
- Include the user's original prompt verbatim in the commit body, prefixed with `Prompt:` followed by a space — not in the title.
- Reference issue numbers in commit messages when applicable.
- Commit messages must be written in UK English.

## 6. Push (MANDATORY)

- Push to `origin` after every commit.
- **Always push a new branch with `-u`** to set up tracking: `git -C <repodir> push -u origin <branch>`. Subsequent pushes can use `git -C <repodir> push`.

## General Git Command Rules

- Always use `git -C <dir> <command>` — never `cd <dir> && git <command>`.
- When any git command fails, quote the exact stdout and stderr verbatim in any issue or PR comment before offering a diagnosis — never substitute a narrative for the actual error output.
- Pre-commit hooks may make commits slow — wait for them to complete before assuming failure.

## After Pushing

If the remote reports vulnerabilities:

- Check for open Dependabot PRs covering them (`gh pr list --label dependencies`).
- If none exist, for any manually fixable advisory create a GitHub issue labelled `Security` and `AI-Work`, naming the package, severity, and fix steps.
