---
name: credfeto-git-commit
description: Commit and push changes safely — branch checks, build/test gates, Conventional Commits format, and push cadence. Use whenever about to commit, stage, or push changes in any repository, or when acting as the Committer agent.
---

# Git Commit Workflow

Follow every step below, in order, for every commit.

## 1. Build and Test Verification (MANDATORY)

Build must pass and all tests must pass before committing or pushing. If they fail and cannot be resolved, stop and ask.

## 2. Branch Check (MANDATORY)

- Run `git branch --show-current` and confirm it is the expected working branch before staging or committing.
- **Never commit if the current branch is `main`.**
- If the branch has switched to `main` and the upstream no longer exists (merged and deleted), create a new branch before continuing.

## 3. Commit Rules (MANDATORY)

- **Never create an empty commit.** Verify `git diff --cached --name-only` lists at least one file before running `git commit`.
- Never amend an existing commit — always create a new one.
  - **Exception:** for a commit that has not yet been pushed to `origin`, the commit message may be amended (e.g. to fix wording or apply the Commit Message Format below). The set of files in the commit and their content must never be changed by such an amend — only the message.
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

## 4. Commit Message Format

- Use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) format.
- Include the user's original prompt verbatim in the commit body, prefixed with `Prompt:` followed by a space — not in the title.
- Reference issue numbers in commit messages when applicable.
- Commit messages must be written in UK English.

## 5. Push (MANDATORY)

- Push to `origin` after every commit.
- **Always push a new branch with `-u`** to set up tracking: `git -C <repodir> push -u origin <branch>`. Subsequent pushes can use `git -C <repodir> push`.

## General Git Command Rules

- Always use `git -C <dir> <command>` — never `cd <dir> && git <command>`.
- When any git command fails, quote the exact stdout and stderr verbatim in any issue or PR comment before offering a diagnosis — never substitute a narrative for the actual error output.
- Pre-commit hooks may make commits slow — wait for them to complete before assuming failure.

## After Pushing

If the remote reports vulnerabilities:

- Check for open Dependabot PRs covering them (`gh pr list --label dependencies`).
- If none exist, visit the repo's Dependabot page and for any manually fixable advisory create a GitHub issue labelled `Security` and `AI-Work`, naming the package, severity, and fix steps.
