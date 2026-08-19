---
name: credfeto-git-commit
description: Commit and push changes safely, covering branch checks, build/test gates, Conventional Commits format, push cadence, and the additional GPG-signing and hook-escalation rules that apply when acting as the Committer agent. Use whenever about to commit, stage, or push changes in any repository, or when acting as the Committer agent.
---

# Git Commit Workflow

Follow every step below, in order, for every commit.

## 1. Build and Test Verification (MANDATORY)

Write unit tests before every commit; every new behaviour must have corresponding tests. Build must pass and all tests must pass before committing or pushing. If they fail and cannot be resolved, stop and ask.

## 2. Branch Check (MANDATORY)

- Run `git branch --show-current` and confirm it is the expected working branch before staging or committing.
- **Never commit if the current branch is `main`.**
- If the branch has switched to `main` and the upstream no longer exists (merged and deleted), create a new branch before continuing.

## 3. Commit Rules (MANDATORY)

- **Never create an empty commit.** Verify `git diff --cached --name-only` lists at least one file before running `git commit`.
- Never amend an existing commit; always create a new one.
  - **Exception:** for a commit that has not yet been pushed to `origin`, the commit message may be amended (e.g. to fix wording or apply the Commit Message Format below). The set of files in the commit and their content must never be changed by such an amend, only the message.
- One logical change per commit; do not batch unrelated changes.
- **Never bypass hooks or formatters.** If they fail, stop and report the failure.
- **Never bypass commit message validation.** If it fails, stop and report the failure.
- **Never change linting or formatting rules to force a commit through.** If they fail, stop and report the failure.
- **Never modify ignore files to force a commit through.** If they cause a failure, stop and report the failure.

### Unexpected reformatting during commit

If hooks or formatters modify files **not in your intended change set**:

1. Do not stage the unrequested changes.
2. Abort the commit.
3. Report the affected files and which hook/formatter changed them.
4. Wait for explicit instructions.

## 4. Commit Message Format

- Use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) format.
- Include the user's original prompt verbatim in the commit body, prefixed with `Prompt:` followed by a space, not in the title.
- Reference issue numbers in commit messages when applicable.
- Commit messages must be written in UK English.
- Do not use em dash characters (`—`) in commit messages; use a comma, colon, semicolon, or separate sentences instead.

## 5. Push (MANDATORY)

- Push to `origin` after every commit.
- **Always push a new branch with `-u`** to set up tracking: `git -C <repodir> push -u origin <branch>`. Subsequent pushes can use `git -C <repodir> push`.

## Committer Agent Additional Rules (MANDATORY when acting in that role)

When acting specifically as the dedicated Committer agent in a multi-agent workflow (split from Code Writer, PR Submitter, and other roles):

- Use the `git` CLI only for commit and push; never `gh` or the GitHub API.
- For the placeholder step (no code exists yet): commit the placeholder artefact alone: `CHANGELOG.md`, or `.deleteme.now` (a short delete-before-merge comment as its content) for repos that skip changelog entries, such as `credfeto/cs-template` itself.
- Otherwise: commit code and tests as one **GPG-signed** commit (Conventional Commits format, original prompt in the body as `Prompt: …`), and commit `CHANGELOG.md` separately, also GPG-signed, whenever a changelog correction accompanies it.
- Push immediately after committing. Do not open the pull request yourself; PR creation/update is a separate, later step owned by another role.
- **Do not use `--no-verify`.** If a pre-commit hook fails: capture the output, report it to the agent that produced the change, re-stage, and retry. **Escalate to the Orchestrator after 3 failed cycles.**

Outside that specific role split, sections 1-5 above are the complete workflow.

## General Git Command Rules

- Always use `git -C <dir> <command>`; never `cd <dir> && git <command>`.
- When any git command fails, quote the exact stdout and stderr verbatim in any issue or PR comment before offering a diagnosis; never substitute a narrative for the actual error output.
- Pre-commit hooks may make commits slow; wait for them to complete before assuming failure.

## Never Truncate Test/Commit Commands (MANDATORY)

`git commit`/`pre-commit` has no bounded, predictable duration: `pre-commit` can run a heavy hook chain (e.g. full-project build checks, security scanners, lint stacks), and a commit has already been killed mid-run on a foreground timeout in a live session. There is no timeout value that is both practical and safe to pick, so do not try to pick one.

- **Always run `git commit` (including its pre-commit hook run) via `run_in_background`; never in the foreground, regardless of how fast the specific run is expected to be.** This is unconditional, not a per-invocation judgement call.
- Poll with the Monitor tool for a specific string the command itself writes, subject to a 30-minute deadline:
  - Pre-commit hooks passed: poll for `→ All checks passed.`
  - Pre-commit hooks failed: poll for `→` followed by `Failed` (check for both to distinguish pass/fail).
  - If `git push` is also backgrounded (not itself required to run in the background), poll for `branch` (the branch tracking line in push output).
- Never poll for `"exit code"`; that string is not reliably written to background task output files.
- A long stretch with no new output is normal and is not a hang. Do not interpret silence as a failure and manually cancel or kill the command on that basis; the only valid reasons to stop waiting are the tool itself reporting its timeout was hit, or the poll-loop deadline actually firing.
- A killed run does not just fail; it skips the target process's own cleanup, leaving orphaned temp directories, lock files, or half-applied state behind. A `git commit` has been killed mid-run on a foreground timeout in practice; do not repeat this.
- If the 30-minute deadline fires, mark the work item `Blocked` and stop rather than continuing work.

## After Pushing

If the remote reports vulnerabilities:

- Check for open Dependabot PRs covering them (`gh pr list --label dependencies`).
- If none exist, visit the repo's Dependabot page and for any manually fixable advisory create a GitHub issue labelled `Security` and `AI-Work`, naming the package, severity, and fix steps.

## Instruction File Source Routing

Before committing a change to an instruction file (`ai/global/**` or `ai/local/**`), route it to the correct repository:

- Changes to shared global instruction files (`ai/global/**`): raise an issue in `credfeto/cs-template`; it is the canonical source for those files. See [Template Rule Escalation](#template-rule-escalation-non-template-repos-only) below for the issue format.
- Changes specific to FunFair server projects: raise an issue in `funfair-tech/funfair-server-template` instead.
- Otherwise (local instructions specific to the current repository): make the change directly in the current repository and commit it as normal.

## Template Rule Escalation (Non-Template Repos Only)

When working outside `credfeto/cs-template` and a gap in the global template rules is found:

1. Do not apply the change locally.
2. Create an issue in `credfeto/cs-template` using the command template below.
3. The issue must include: source repository, current behaviour/gap, proposed rule text, reason for template propagation.
4. Note the issue URL in any relevant commit or PR description.
5. Continue work without waiting for the template issue to be resolved.

```bash
gh issue create --repo credfeto/cs-template \
  --title "<short description of the rule change>" \
  --label "AI-Work" \
  --body "**Source repository**: <repo where need was discovered>

**Current behaviour / gap**: <what is missing or inconsistent>

**Proposed rule text**: <concrete rule update or new instruction text>

**Reason for template propagation**: <why this should apply across all repos>"
```
