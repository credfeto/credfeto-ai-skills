---
name: credfeto-git-commit
description: Commit and push changes safely, covering branch checks, build/test gates, Conventional Commits format, push cadence, and the additional GPG-signing and hook-escalation rules that apply when acting as the Committer agent. Use whenever about to commit, stage, or push changes in any repository, or when acting as the Committer agent.
---

# Git Commit Workflow

Follow every step below, in order, for every commit.

## 1. Build and Test Verification (MANDATORY)

Write unit tests before every commit; every new behaviour must have corresponding tests. Build must pass and all tests must pass before committing or pushing. If they fail and cannot be resolved, stop and ask.

### Fixing pre-commit failures (MANDATORY)

Pre-commit and its component tools (e.g. `dotnet buildcheck`, analyzers, linters) are improved incrementally precisely by encountering and fixing the problems they surface. If pre-commit reports an error that was not present before the current work started, whether caused by your own edits or a component tool catching something pre-existing, fixing it is part of the current work, not a reason to stop.

- Do not stop, escalate or add `Blocked` merely because the failure is unexpected, was not present originally, also fails on main, or requires changes outside the files you set out to edit (however many), including the pre-commit configuration or a component tool's own rules/config. Fix it in the current PR, because the PR cannot pass its checks until it is fixed.
- Only stop and ask if the issue is genuinely fatal: pre-commit cannot possibly be made to pass (e.g. a required external tool is missing from the environment and cannot be installed, or the cause is infrastructure outside the repo's control), or the only fix is a suppression, skip or exclusion that needs authorisation.
- This does not relax Build and Test Verification above: the fix must be a genuine fix, not a suppression, skip, or exclusion, unless separately authorised.
- If a component tool's fix is a package change (adding, changing, or removing a package reference), this does not automatically require the standard new-package approval-and-wait; follow the pre-commit/component-tool package-change conflict-resolution path instead, which still falls back to approval-and-wait if its own security review finds a genuine blocker.

### Pre-commit hook verification (MANDATORY before blocking)

Never block work based on inspecting config files and deducing that a tool might be missing. Always verify empirically: stage your changes and run `git commit` as normal; the pre-commit hook runs automatically and aborts the commit cleanly if it fails, leaving your staged changes intact. Only block if that actually fails with a real error.

Inspecting `.pre-commit-config.yaml` and concluding a `language: system` tool is absent is not sufficient; the tool may be installed in a location not visible to `command -v` in the current shell context.

Known hook incompatibility: for `dotenv-linter`, use `entry: dotenv-linter check`; v3.x requires the `check` subcommand before the filename.

## 2. Branch Check (MANDATORY)

- Run `git -C <dir> branch --show-current` and confirm it is the expected working branch before staging or committing.
- **Never commit if the current branch is `main`.**
- If the branch has switched to `main` and the upstream no longer exists (merged and deleted), create a new branch before continuing.

## 3. Commit Rules (MANDATORY)

- **Never create an empty commit.** Verify `git -C <dir> diff --cached --name-only` lists at least one file before running `git commit`.
- Never amend an existing commit; always create a new one.
  - **Exception:** for a commit that has not yet been pushed to `origin`, the commit message may be amended (e.g. to fix wording or apply the Commit Message Format below). The set of files in the commit and their content must never be changed by such an amend, only the message.
- One logical change per commit; do not batch unrelated changes. Each change is made, tested and committed before the next starts.
- Refactoring, dead code removal and incidental file cleanup are each committed separately from feature/fix changes; tests must pass after every such commit. Dead code removal is one method or function per commit, and cleanup of several distinct fix types in a file is one commit per fix type, per file.
- Commit from a working tree that holds exactly one change. Never split a tree holding several changes into commits by file or by hunk; hand it back to the Orchestrator instead.
- Do not run `pre-commit-check` separately before a commit: `git commit` runs the same hooks automatically, so a separate run only repeats work the commit does anyway. When a commit fails on a hook, fix the cause and retry the commit.
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
- Reference issue numbers in commit messages when applicable.
- Commit messages must be written in UK English.
- Do not use em dash characters (`—`) in commit messages; use a comma, colon, semicolon, or separate sentences instead.

### Pattern Sweep Commits

A commit produced by the Pattern Sweep rule (searching the whole repository for other occurrences of a construct after fixing a bug or accepting a review finding) must, in addition to the rules above:

- Follow its own fix commit immediately, before the next change is started; the exception is a Phase A post-convergence sweep in the AI Review Loop, which has no fix commit of its own.
- Use the Conventional Commits type of the fix commit it derives from (the oldest, when it derives from several; `refactor` for a Phase A sweep of `/simplify` changes), with a title that states it is a sweep, e.g. `fix: apply null-guard fix to remaining call sites`.
- Carry a `Construct: <one line naming the construct searched for>` line; this exact prefix is what later rounds search commit bodies for.
- Reference every fix commit SHA it derives from and, where one exists, the review comment or finding.
- List every file touched, one line per file, each stating why that site matches the original finding.
- A fix commit that carries sweep hunks in files it already touches carries the same `Construct:` line and per-file lines; a fix commit whose sweep found nothing carries `Construct:` and `Swept: none`.

## 5. Push (MANDATORY)

- Push to `origin` after every commit, or once after a run of consecutive commits when pushes are batched; the branch is always pushed before PR Submitter or CI Monitor runs and before the session ends.
- Pre-commit hooks may make commits slow; wait for them to complete before assuming failure.
- For coverage tasks, work file by file: write tests until the file reaches target coverage, commit the test file and push immediately, update the sub-issue to mark the file done, then move to the next file. For complex files, commit, push and update after each round rather than waiting until the file is fully complete.
- **Always push a new branch with `-u`** to set up tracking: `git -C <repodir> push -u origin <branch>`. Subsequent pushes can use `git -C <repodir> push`.

## Committer Agent Additional Rules (MANDATORY when acting in that role)

When acting specifically as the dedicated Committer agent in a multi-agent workflow (split from Code Writer, PR Submitter, and other roles):

- Use the `git` CLI only for commit and push; never `gh` or the GitHub API.
- For the placeholder step (no code exists yet): commit the placeholder artefact alone: `CHANGELOG.md`, or `.deleteme.now` (a short delete-before-merge comment as its content) for template-skip repos.
- Otherwise: a hand-off holds exactly one change. Commit it as one **GPG-signed** commit (Conventional Commits). When the hand-off carries its sweep record, stage by whole file: everything except the sweep-only files is the fix commit, then build once, then commit the sweep-only files as the sweep commit per the Pattern Sweep Commits format above. When the hand-off is a sweep alone (a Phase A post-convergence sweep), there is only the sweep commit. Commit `CHANGELOG.md` as a separate GPG-signed commit whenever a changelog correction accompanies it.
- If the working tree or the hand-off holds more than one change (for example more than one sweep record or `Construct:` line, or changes the hand-off does not describe), commit nothing: hand it back to the Orchestrator to route each change again on its own. Never split a mixed tree into commits by file or by hunk.
- Push after the commit, or after a run of consecutive commits when pushes are batched; the branch is always pushed before handing back. Do not open the pull request yourself; PR creation/update is a separate, later step owned by another role.
- **Do not use `--no-verify`.** If a pre-commit hook fails: capture the output, report it to the agent that produced the change, re-stage, and retry. **Escalate to the Orchestrator after 3 failed cycles.**

## General Git Command Rules

- Always use `git -C <dir> <command>`; never `cd <dir> && git <command>`.
- When any git command fails, quote the exact stdout and stderr verbatim in any issue or PR comment before offering a diagnosis; never substitute a narrative for the actual error output. Run the failing command as its own call, then paste its output, unchanged, into the comment body as a separate call, quoting the heredoc delimiter (`'COMMENT'`) so the shell does not expand `$` or backticks in the pasted output.

## File Names and Git File Lists (MANDATORY)

- Name every file you create with ASCII characters only, because git, shells and CI tools quote, escape or mangle non-ASCII names and break the scripts that read them.
- Read git file lists NUL-separated, never split on newlines: files from elsewhere may have any name, and without `-z` git quotes and escapes non-ASCII or quote-containing paths, so the printed names no longer match the files.
  - Produce the list with `-z`: `git ls-files -z`, `git diff --name-only -z`.
  - Split captured output with `split('\0').filter(Boolean)`, because `-z` also ends the last entry with NUL and a plain split leaves a trailing empty name.

## Never Truncate Test/Commit Commands (MANDATORY)

`git commit`/`pre-commit`/`pre-commit-check` has no bounded, predictable duration: `pre-commit` can run a heavy hook chain (e.g. full-project build checks, security scanners, lint stacks). There is no timeout value that is both practical and safe to pick, so do not try to pick one.

- **Always run `git commit` (including its pre-commit hook run) via `run_in_background`; never in the foreground, regardless of how fast the specific run is expected to be.** This is unconditional, not a per-invocation judgement call.
- **Run only one long-running command at a time.** Never start a commit, build, test or lint run (`git commit`/`pre-commit`/`pre-commit-check`, `dotnet build`, `dotnet test`, `npm test`, `bun test`, or any other build, test or lint run started in the background) while another one you started is still running: wait for the first command's completion marker before starting the next, and run several checks one after another, never in parallel. Each of these commands can use most of a small host's memory, and two at once can get the whole session OOM-killed, losing every in-flight task.
- **Never wrap it in a shell `timeout` command** as a substitute or a belt-and-braces addition, whether or not `run_in_background` is also set; plain `run_in_background` on the unwrapped command is already unbounded and needs no additional wrapper.
- Poll with the Monitor tool for a specific string the command itself writes, subject to a 30-minute deadline:
  - Pre-commit hooks passed: poll for `→ All checks passed.`
  - Pre-commit hooks failed: poll for `→` followed by `Failed` (check for both to distinguish pass/fail).
  - `git push` completed: poll for `branch` (the branch tracking line in push output).
- Never poll for `"exit code"`; that string is not reliably written to background task output files.
- A long stretch with no new output is normal and is not a hang. Do not interpret silence as a failure and manually cancel or kill the command on that basis. Never stop waiting for the completion marker: when the 30-minute poll-loop deadline fires, report the overrun (to the human in an interactive session, or as a comment on the work item without the `Blocked` label in an unattended run) and start a new watch on the same completion marker; when a `Monitor` watch's own timeout expires first, start a new watch.
- Never stop a commit or push that is still running with `TaskStop`, and never hand back while it is still running; wait for its completion marker. Once it has finished, stop any `Monitor` watch you started.
- A killed run does not just fail; it skips the target process's own cleanup, leaving orphaned temp directories, lock files, or half-applied state behind.

## Work That Cannot Be Committed (MANDATORY)

When a session cannot save its work through a commit (a file-edit, commit or push tool is denied, or the environment will not outlive the session), the work must not be lost silently, because the next run would otherwise redo it from scratch or never learn it was attempted.

- **P1.** Keep your own uncommitted changes: before any command that can discard them, run `git status` and stash or commit anything you did not just create and intend to discard; discard only changes you can see are wrong, never as stray churn.
- **P2.** Before the session ends, record the work in a single comment on the PR (or the issue if there is no PR yet), editing it if it already exists. Start it with the hidden marker `<!-- uncommitted-work -->`, then give the tool or action that was denied, the branch name, the base commit SHA and a precise description of the change (a `Construct:` line and file list, as for a Pattern Sweep) so it can be re-applied if the diff no longer applies. The base is where the local work diverged from the pushed branch (`git merge-base HEAD @{upstream}`, or `git merge-base HEAD origin/main` when the branch was never pushed), so the diff includes local commits whose push was denied but never reverts someone else's pushed commits. Capture the diff of only the files you changed with `git add -N <files that still exist>` then `git -C <dir> diff --binary <base> -- <files>` (listing deleted files too), so your new files, staged changes and unpushed commits are included but no other untracked file is, and never include a file holding secrets, because the comment may be public. Put the diff in a collapsed `<details>` block if the whole comment body then stays under 60,000 characters; otherwise the description alone is the record.

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
2. Create an issue in `credfeto/cs-template` using the command template below. The title is `prefix: text` or `prefix(name): text` with a lower-case prefix: the prefix a specific rule gives, or failing that a Conventional Commits type that matches the work (a local title rule takes precedence where one exists).
3. The issue must include: source repository, current behaviour/gap, proposed rule text, reason for template propagation.
4. Note the issue URL in any relevant commit or PR description.
5. Continue work without waiting for the template issue to be resolved.

```bash
gh issue create --repo credfeto/cs-template \
  --title "<prefix>: <short description of the rule change>" \
  --label "AI-Work" \
  --body "**Source repository**: <repo where need was discovered>

**Current behaviour / gap**: <what is missing or inconsistent>

**Proposed rule text**: <concrete rule update or new instruction text>

**Reason for template propagation**: <why this should apply across all repos>"
```
