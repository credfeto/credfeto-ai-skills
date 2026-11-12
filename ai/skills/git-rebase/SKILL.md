---
name: credfeto-git-rebase
description: Determine whether a resumed work branch needs rebasing onto an updated origin/main, resolve version conflicts (package, GitHub Actions, or runtime/tool versions) that arise during a merge or rebase, and apply the additional CHANGELOG.md conflict, force-push and escalation rules that apply when acting as the dedicated Rebase Agent. Use whenever resuming an existing branch before making a new commit, before running the pre-commit health check on a branch that already existed, whenever a merge or rebase produces conflicting versions of the same package, action, or runtime in a dependency manifest, workflow file, or version file, or when acting as the Rebase Agent.
---

# Git Rebasing

## When to Rebase

If already on the correct, existing work branch for this task (i.e. resuming work rather than branching fresh from `main`), bring it up to date before running the pre-work baseline check, as three distinct, ordered steps:

1. **Fetch**: `git -C <repodir> fetch origin main`. Always fetch first, regardless of whether a rebase turns out to be needed.
2. **Check**: `git -C <repodir> rev-list --count HEAD..origin/main`. A non-zero count means `origin/main` has advanced and a rebase is needed.
3. **Rebase**: only if step 2 found new commits, rebase onto `origin/main` now, following the version-conflict-resolution algorithm below and, when the branch has already been pushed, the Force-Pushing a Rebased Branch rules below, then run the After Every Rebase check below.

A branch just created fresh from an up-to-date `main` does not need this; it starts current by construction.

Whenever rebasing from `main`, take the current branch's changes, but merge the changes in from `main` into the current fileset.

### After Every Rebase (MANDATORY)

A rebase pulls in unknown content from `origin/main` (other people's commits, plus any conflict resolutions), so every rebase, of any form and for any reason, leaves the branch unverified until this check passes. It applies to every rebase in a session, not only the first one. The dedicated Rebase Agent does not run it itself, so the Orchestrator runs it as the Post-Rebase Check once the rebase is complete, or the role that performed the rebase directly runs it itself. The Orchestrator never implements directly, so it hands every fix, commit and push to the review-fix route (Code Fixer, Code Tester, Committer, PR Submitter, CI Monitor) rather than editing files itself.

1. Run the build and tests, then run `pre-commit-check` against all tracked files, in the background, waiting for it to finish and judging it by its exit code before continuing.
2. Fix every issue it reports, including issues that were already present before the rebase, because it covers the whole repository. Re-run `pre-commit-check` after each round of fixes and repeat until it reports no issues. Do not continue with any other work while issues remain, and do not suppress or weaken a check to make it pass.
3. Commit each fix as its own commit on the current branch, separate from the rebase and from fixes to other constructs. If the check only auto-fixes files (for example trailing whitespace) with everything else passing, commit those fixes on the current branch in their own commit.
4. Only for an issue where pre-commit cannot possibly be made to pass (for example a required external tool is missing from the environment and cannot be installed, the cause is infrastructure outside the repo's control, or the only fix is a suppression, skip or exclusion that needs authorisation): comment on the issue/PR with the verbatim output and label it `Blocked`. Difficulty is not a reason to escalate.
5. No coverage re-baseline step is needed: the AI Coverage phase always reads `COVERAGE.md` live from `origin/main`, so a rebase alone cannot make it stale. If the rebase itself produces a conflict in `COVERAGE.md`, do not hand-merge the numbers.

## Force-Pushing a Rebased Branch (MANDATORY)

Rebasing a pushed branch rewrites its history, so pushing it needs a force-push. That is allowed only for a pure rebase that passes every check below, because a force-push to a shared branch, or over commits someone else pushed, destroys their work. This applies to every role that rebases a pushed branch, including the Rebase Agent.

1. Before rebasing, refuse `main`, `master`, `develop`, `release/*` and any other shared branch: only a personal feature or topic branch may be rebased and force-pushed.
2. Before rebasing, fetch the branch (`git -C <repodir> fetch origin <branch>`) and confirm that local HEAD equals remote HEAD: `git -C <repodir> rev-parse refs/heads/<branch>` must print the same SHA as `git -C <repodir> rev-parse refs/remotes/origin/<branch>`, because a difference means the local branch is not what was pushed, so the force-push would not be a pure rebase of the remote branch and could drop commits pushed from elsewhere.
3. Push with `git -C <repodir> push --force-with-lease origin <branch>` only. Never use plain `--force` (or `-f`), because only the lease refuses to overwrite commits pushed since the fetch.
4. If any check above fails, or the push is rejected, stop and ask the human, quoting the output verbatim. Do not retry the push and do not fall back to plain `--force`.

## Resolving Version Conflicts When Merging or Rebasing

When a merge or rebase produces conflicting versions of the same package, action, or runtime (both branches changed the version), resolve each conflicting entry individually. Never take a whole file wholesale from one side.

This applies to every version-bearing file, including:

- Dependency manifests: `.csproj`, `Directory.Packages.props`, `packages.config`, `package.json`, `requirements.txt`
- GitHub Actions `uses:` version pins in workflows and composite actions
- Runtime and tool versions: .NET SDK (`global.json`), `dotnet-tools.json`, Node.js (`.nvmrc`, `engines`, `setup-node` versions), Python (`.python-version`, `setup-python` versions), and similar

Rules:

1. Take the **latest** of the candidate versions.
2. **Stable-over-pre-release exception**: if one candidate is a stable (release) version and the other is a pre-release (alpha/beta/rc/preview/dev build, etc.), take the stable candidate even if the pre-release has a nominally higher version number. Only take a pre-release if every candidate is a pre-release, in which case take the latest of them.
3. **Security exception**: if the latest candidate is known to be less secure than another candidate (e.g. it has a published security advisory that the other does not), take the most recent candidate that is not affected.
4. Never resolve by downgrading below every candidate, and never invent a version that appears on neither side.
5. Lock files (`package-lock.json` and similar): do not hand-merge; resolve the manifest first, then regenerate the lock file with the package manager.
6. After the merge or rebase completes, run the build and tests. If the chosen version broke the build (API changes, removed features), fix the breakage on the same branch as part of the merge work; do not downgrade to avoid the fix.

### No Confirmation Needed When the Algorithm Resolves the Conflict

Rules 1-5 above are a complete, deterministic algorithm: for every conflicting entry there is exactly one correct resolution (the latest candidate, the stable candidate, or the security-exception candidate). Apply it and continue; do not stop a merge or rebase to ask for confirmation on a conflict this algorithm resolves unambiguously, and do not post a PR/issue comment asking someone to confirm the choice.

Only stop and ask when a conflict genuinely falls outside the algorithm, for example:

- The same package is bumped to two different, unrelated versions on both sides and there is no clear "latest" (e.g. divergent major versions).
- A security trade-off with no candidate that is both latest and unaffected.

## Rebase Agent Role (MANDATORY when acting in that role)

When acting specifically as the dedicated Rebase Agent:

- Rebase the named branch onto `origin/main`, only after the pre-rebase checks in Force-Pushing a Rebased Branch above pass: refuse `main`, `master`, `develop`, `release/*` and any other shared branch, and confirm `refs/heads/<branch>` equals `refs/remotes/origin/<branch>` after fetching. If either check fails, stop and ask; do not rebase.
- `CHANGELOG.md` conflicts: keep the entries from both sides rather than picking one.
- If the branch has an open PR, take it back before force-pushing with `cfwf pr take-back --repo <owner/repo> --pr <number> --body-file <file|->`, with a body saying why (the rebase about to be pushed), because a rebase changes the head, so the rebased commit is unreviewed and GitHub could otherwise merge it as soon as its checks pass, before the AI Review Loop reviews it. It turns auto-merge off first, then converts the PR to draft, moves the board to **Development** and posts the body as a comment. The order matters: converting to draft alone is not enough, because GitHub does not turn auto-merge off when a PR becomes a draft. Never do these steps separately.
- If the version conflict resolution chosen per the algorithm above breaks the build, report the break to the Orchestrator instead of fixing it directly; fixing build breakage is not the Rebase Agent's job in that scoped role.
- Any other conflict, including one that falls outside the deterministic algorithm above: report it verbatim to the Orchestrator; do not resolve it yourself.
- Force-push with `--force-with-lease` only, never plain `--force`, and only after all conflicts are resolved. If the push is rejected, stop and ask, with no retry and no fallback to plain `--force`.
- When a hook blocks a command and no form of the same operation that the hook accepts exists, put the blocked command and the hook's message, both verbatim, in your hand-off report to the calling role. Never ask the caller to run the command, and never work around the block, including by creating or editing a settings, permission or hook file, a hook's data file (such as its command allowlist) or any other Claude Code configuration, or by invoking `update-config` or any other configuration-editing skill.
- Never start a long-running command (such as a build or test run) while another one you started is still running; wait for the first command's completion notification before starting the next.
- Do not run `pre-commit-check` or fix what it reports: that is the After Every Rebase check above, which the Orchestrator runs once this role returns, because this role is mechanical and must not interpret or fix failures.
