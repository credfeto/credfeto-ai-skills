---
name: credfeto-git-branch
description: Create, name, and maintain git branches, covering branching rules, git safety checks before destructive or worktree operations, Conventional Commits-style branch naming, rebasing against main, resuming interrupted work, and resolving version conflicts in dependency manifests during merges/rebases. Use when starting new work, creating a branch, resuming work on an existing branch, rebasing, switching branches, or resolving merge conflicts.
---

# Git Branching Workflow

## Branching Rules

- All new work must be in a branch; **never commit directly to `main`**.
- Ensure `main` is up-to-date with `origin` before starting.
- Continue in the same branch until the task changes.
- Before continuing work on an existing branch, check if `origin/main` has advanced; if so, rebase first.
- Only one active branch or open PR per user per repository at a time; do not create another until the current one is merged and closed.
- **Before blocking new work** because of an existing PR: always verify its current state with `gh pr view <number> --repo <owner/repo> --json state,mergedAt`; never rely on conversation memory. A PR that was open earlier in the session may have since been merged.
- Always use `git -C <dir> <command>`; never `cd <dir> && git <command>`.

## Destructive Commands (MANDATORY)

Before any command that can discard uncommitted work (`git reset --hard`, `git checkout`/`restore` over tracked files, `git clean`), run `git status` first. If it shows uncommitted changes you did not just create and intend to discard, stash them (`git stash -u`, `-u` to include untracked files) or commit them before proceeding. Running the destructive command directly on the assumption the tree is clean, without checking, silently discards any uncommitted work that is there; the check costs one command and is never skippable "because it should be clean".

## Avoid `git worktree`

- Do not use `git worktree` or the native `EnterWorktree` tool to create additional working trees for a repo.
- Switch branches in the existing working directory (`git -C <dir> checkout <branch>` / `git -C <dir> switch <branch>`) instead.

## Scratch Review Branches

A local branch created only to review a PR, named `pr<number>-review` or `pr-<number>-review`, may be deleted without asking once the review is done, because it is a throwaway copy of an existing PR head and holds no work of its own.

- Create it tracking the PR head: `git fetch origin +refs/pull/<number>/head:refs/remotes/origin/pr/<number>`, then `git branch --track pr<number>-review origin/pr/<number>`. `git branch -d` checks a branch against its upstream, so without one it checks against HEAD and refuses while the PR is still open, even though every commit is safe on the PR head.
- Delete it with the same fetch chained to `git branch -d`, never `-D`: `git fetch origin +refs/pull/<number>/head:refs/remotes/origin/pr/<number> && git branch -d pr<number>-review`. The fetch is repeated because `origin/pr/<number>` sits inside origin's default refspec with no matching branch on origin, so any plain `git fetch origin` or `git pull` with `fetch.prune` set deletes it, and `-d` then checks against HEAD and refuses even an unchanged branch; the ref cannot live outside `refs/remotes/origin/*` instead, because `git branch --track` only accepts a ref that a remote's refspec maps. `-d` refuses unless the branch is merged into its upstream (or into HEAD when it has none). A branch still equal to the PR head is deleted (exit 0; the warning that it is not yet merged to HEAD is expected); a branch left with local commits is refused as `not fully merged` (exit 1). If git refuses, keep the branch and report it rather than forcing the deletion, because those local commits would otherwise be lost.
- This covers local branches only. Deleting a remote branch, or any other local branch, still needs human approval.

## Branch Naming

Format: `<type>/<name>` (mirroring Conventional Commits types):

- `feature/add-user-auth`
- `fix/null-pointer-on-login`
- `chore/update-dependencies`
- `refactor/simplify-payment-flow`

Include the issue number when applicable: `fix/123-null-pointer-on-login`.

For branches fixing multiple issues, reference each issue number in the individual commit message bodies.

## Before Creating a Branch

Check for existing work (MANDATORY):

1. Run `gh pr list --state open --repo <owner/repo> --json number,title,author,headRefName,url`, no `--author @me` filter.
2. If any open PR's `headRefName` contains the issue number, that is prior work; resume it instead of creating a new branch.
3. For any PR authored by `app/github-actions` (github is configured to auto-create PRs from pushed branches; these appear bot-authored but the commits are yours), verify the commit authors before taking ownership: `gh pr view <n> --repo <owner/repo> --json commits --jq '.commits[].authors[].login'`. If **all commits** are from your account, take ownership rather than duplicating work: update the title/body to match the proper format, add yourself as assignee, and treat it as your active PR. If commits are from multiple authors (e.g. you plus a human or Copilot), do **not** take over; leave the PR as-is.
4. Do **not** create a new branch or PR for the same issue; that would be duplicate work. If a duplicate pair already exists (a bot-created PR and one you authored yourself, for the same issue or branch): keep whichever has the more complete body and later review activity, and close the other with a comment explaining which PR supersedes it.
5. This only catches work that already has an open PR. A branch may have been pushed and then abandoned before a PR was ever opened (e.g. a prior session died mid-task), so also check for a matching branch directly, using the `<type>/<issue-number>-<name>` naming convention above:

   ```bash
   git ls-remote --heads origin "*/<issue-number>-*"
   ```

   - No match: branch fresh from `main` as normal.
   - Match found: fetch it and compare against `main`:

     ```bash
     git fetch origin <branch>
     git rev-list --count origin/main..origin/<branch>
     ```

     - `0` (not ahead of `main`): branch fresh from `main` as normal.
     - `>0`: check it out and continue from there instead of branching again, rebasing first (see Rebasing below) if `origin/main` has advanced.

## Resuming Interrupted Work

When resuming work after an interruption:

- Check the status of existing issues and branches; skip merged branches.
- Check the PR or issue for an `<!-- uncommitted-work -->` comment and act on it only when both its author and its last editor are the agent's own bot login or a trusted commenter. If the PR (or issue) has since been merged or closed, edit the comment to say so, removing the marker, and stop. Otherwise check out the recorded branch (creating it from the recorded base if it was never pushed); unless the working tree already holds the recorded change, apply the recorded diff (`git apply --3way`) or re-apply the described change if the diff no longer applies. Hand the result to the role that would have committed it so it gets the normal build, test and commit steps, and only once that has pushed replace the comment's whole body with `Applied in <sha>`.
- For unmerged branches, decide whether to continue or delete and recreate.
- Update the top-level issue with current status and next steps before resuming.

## Pushing Branches

- **Always push a new branch with `-u`**: `git -C <repodir> push -u origin <branch>`.
- Subsequent pushes on a tracked branch can use `git -C <repodir> push`.
- Never push without `-u` on the first push; without it the branch has no upstream and later `git push`/`git pull` commands will fail.

## Rebasing (Pre-Work Baseline Check)

If already on the correct, existing work branch for this task (i.e. resuming work rather than branching fresh from `main`), bring it up to date as three distinct, ordered steps:

1. **Fetch**: `git -C <repodir> fetch origin main`; always fetch first, regardless of whether a rebase turns out to be needed.
2. **Check**: `git -C <repodir> rev-list --count HEAD..origin/main`; a non-zero count means `origin/main` has advanced and a rebase is needed.
3. **Rebase**: only if step 2 found new commits, rebase onto `origin/main` now, following [Resolving Version Conflicts When Merging or Rebasing](#resolving-version-conflicts-when-merging-or-rebasing) below, then run the After Every Rebase check below. If that procedure performed a rebase, it already ran `pre-commit-check` as its final step, and that satisfies the pre-work baseline gate too; do not run it again for that purpose.

A branch just created fresh from an up-to-date `main` doesn't need this; it starts current by construction.

### After Every Rebase (MANDATORY)

A rebase pulls in unknown content from `origin/main` (other people's commits, plus any conflict resolutions), so every rebase, of any form and for any reason, leaves the branch unverified until this check passes. It applies to every rebase in a session, not only the first one. The dedicated Rebase Agent does not run it itself, so the Orchestrator runs it as the Post-Rebase Check once the rebase is complete, or the role that performed the rebase directly runs it itself. The Orchestrator never implements directly, so it hands every fix, commit and push to the review-fix route (Code Fixer, Code Tester, Committer, PR Submitter, CI Monitor) rather than editing files itself.

1. Run the build and tests, then run `pre-commit-check` against all tracked files, in the background and polled to completion before continuing.
2. Fix every issue it reports, including issues that were already present before the rebase, because it covers the whole repository. Re-run `pre-commit-check` after each round of fixes and repeat until it reports no issues. Do not continue with any other work while issues remain, and do not suppress or weaken a check to make it pass.
3. Commit each fix as its own commit on the current branch, separate from the rebase and from fixes to other constructs. If the check only auto-fixes files (for example trailing whitespace) with everything else passing, commit those fixes on the current branch in their own commit.
4. Only for an issue where pre-commit cannot possibly be made to pass (for example a required external tool is missing from the environment and cannot be installed, the cause is infrastructure outside the repo's control, or the only fix is a suppression, skip or exclusion that needs authorisation): comment on the issue/PR with the verbatim output and label it `Blocked`. Difficulty is not a reason to escalate.
5. No coverage re-baseline step is needed: the AI Coverage phase always reads `COVERAGE.md` live from `origin/main`, so a rebase alone cannot make it stale. If the rebase itself produces a conflict in `COVERAGE.md`, do not hand-merge the numbers.

## Resolving Version Conflicts When Merging or Rebasing

When a merge or rebase produces conflicting versions of the same package, action, or runtime (both branches changed the version), resolve each conflicting entry individually; **never take a whole file wholesale from one side**.

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
6. After the merge or rebase completes, run the build and tests. If the chosen version broke the build (API changes, removed features), fix the breakage on the same branch as part of the merge work; do not downgrade to avoid the fix. When acting as the dedicated Rebase Agent, report a build break to the Orchestrator instead of fixing it directly; fixing build breakage is not the Rebase Agent's job.

### No Confirmation Needed When the Algorithm Resolves the Conflict

Rules 1-5 above are a complete, deterministic algorithm: for every conflicting entry there is exactly one correct resolution (the latest candidate, the stable candidate, or the security-exception candidate). Apply it and continue; do not stop a merge or rebase to ask for confirmation on a conflict this algorithm resolves unambiguously, and do not post a PR/issue comment asking someone to confirm the choice.

Only stop and ask when a conflict genuinely falls outside the algorithm, for example:

- The same package is bumped to two different, unrelated versions on both sides and there is no clear "latest" (e.g. divergent major versions).
- A security trade-off with no candidate that is both latest and unaffected.

## CHANGELOG Conflicts

When a merge or rebase produces a conflict in `CHANGELOG.md`, keep the entries from both sides; do not drop either side's changes.

## Rebase Agent Scope (MANDATORY when acting in that role)

- Rebase the named branch onto `origin/main`.
- If the branch has an open PR, turn auto-merge off and convert the PR to draft before force-pushing, because a rebase changes the head, so the rebased commit is unreviewed and GitHub could otherwise merge it as soon as its checks pass, before the AI Review Loop reviews it. Converting to draft alone is not enough, because GitHub does not turn auto-merge off when a PR becomes a draft. Convert with `gh pr ready <number> --repo <owner/repo> --undo`, and turn auto-merge off with `gh pr merge <number> --repo <owner/repo> --disable-auto` only when `gh pr view <number> --repo <owner/repo> --json autoMergeRequest --jq '.autoMergeRequest'` prints something other than `null`, because GitHub does not document what `--disable-auto` does on a PR with no auto-merge request.
- Force-push with `--force-with-lease` only after all conflicts are resolved.
- Any other conflict, i.e. one outside the deterministic algorithm above: report verbatim to Orchestrator; do not resolve it yourself.
- Do not run `pre-commit-check` or fix what it reports: that is the After Every Rebase check above, which the Orchestrator runs once this role returns, because this role is mechanical and must not interpret or fix failures.

## Command Failure Reporting

When any git command fails (push, rebase, fetch, etc.), quote the exact stdout and stderr output verbatim in any issue or PR comment before posting any explanation or diagnosis:

```bash
push_output=$(git -C /path push --force-with-lease 2>&1) || true
gh pr comment NUMBER --repo OWNER/REPO --body "$(cat <<COMMENT
git push failed with:

${push_output}
COMMENT
)"
```

AI-generated diagnoses of command failures are frequently wrong; the verbatim output is always correct.
