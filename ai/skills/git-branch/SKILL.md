---
name: credfeto-git-branch
description: Create, name, and maintain git branches, covering branching rules, Conventional Commits-style branch naming, rebasing against main, resuming interrupted work, and resolving version conflicts in dependency manifests during merges/rebases. Use when starting new work, creating a branch, resuming work on an existing branch, rebasing, or resolving merge conflicts.
---

# Git Branching Workflow

## Branching Rules

- All new work must be in a branch; **never commit directly to `main`**.
- Ensure `main` is up-to-date with `origin` before starting.
- Continue in the same branch until the task changes.
- Before continuing work on an existing branch, check if `origin/main` has advanced; if so, rebase first.
- Only one active branch or open PR per repository at a time; do not create another until the current one is merged and closed.
- Always use `git -C <dir> <command>`; never `cd <dir> && git <command>`.

## Branch Naming

Format: `<type>/<name>` (mirroring Conventional Commits types):

- `feature/add-user-auth`
- `fix/null-pointer-on-login`
- `chore/update-dependencies`
- `refactor/simplify-payment-flow`

Include the issue number when applicable: `fix/123-null-pointer-on-login`.

For branches fixing multiple issues, reference each issue number in the individual commit message bodies.

## Before Creating a Branch

Check for existing work:

1. Run `gh pr list --state open --repo <owner/repo> --json number,title,author,headRefName,url`.
2. If any open PR's `headRefName` contains the issue number, that is prior work; resume it instead of creating a new branch.

## Resuming Interrupted Work

When resuming work after an interruption:

- Check the status of existing branches for the task; skip any that are already merged.
- For an unmerged branch, decide whether to continue on it or delete it and recreate; do not resume it blindly without checking its state first.

## Pushing Branches

- **Always push a new branch with `-u`**: `git -C <repodir> push -u origin <branch>`.
- Subsequent pushes on a tracked branch can use `git -C <repodir> push`.
- Never push without `-u` on the first push; without it the branch has no upstream and later `git push`/`git pull` commands will fail.

## Rebasing (Pre-Work Baseline Check)

If already on the correct, existing work branch for this task (i.e. resuming work rather than branching fresh from `main`), bring it up to date as three distinct, ordered steps:

1. **Fetch**: `git -C <repodir> fetch origin main`; always fetch first, regardless of whether a rebase turns out to be needed.
2. **Check**: `git -C <repodir> rev-list --count HEAD..origin/main`; a non-zero count means `origin/main` has advanced and a rebase is needed.
3. **Rebase**: only if step 2 found new commits, rebase onto `origin/main` now, following [Resolving Version Conflicts When Merging or Rebasing](#resolving-version-conflicts-when-merging-or-rebasing) below. Run the build and tests once the rebase completes.

A branch just created fresh from an up-to-date `main` doesn't need this; it starts current by construction.

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
6. After the merge or rebase completes, run the build and tests. If the chosen version broke the build (API changes, removed features), the default is to fix the breakage on the same branch as part of the merge work; do not downgrade to avoid the fix. **Exception when acting specifically as the dedicated Rebase Agent role** (split from the Code Writer role in a multi-agent setup): report a build break to the Orchestrator instead of fixing it directly; fixing build breakage is not the Rebase Agent's job in that scoped role. Outside that specific role split, the default (fix it) applies.

### No Confirmation Needed When the Algorithm Resolves the Conflict

Rules 1-6 above are a complete, deterministic algorithm: for every conflicting entry there is exactly one correct resolution (the latest candidate, the stable candidate, or the security-exception candidate). Apply it and continue; do not stop a merge or rebase to ask for confirmation on a conflict this algorithm resolves unambiguously, and do not post a PR/issue comment asking someone to confirm the choice.

Only stop and ask when a conflict genuinely falls outside the algorithm, for example:

- The same package is bumped to two different, unrelated versions on both sides and there is no clear "latest" (e.g. divergent major versions).
- A security trade-off with no candidate that is both latest and unaffected.

## CHANGELOG Conflicts

When a merge or rebase produces a conflict in `CHANGELOG.md`, keep the entries from both sides; do not drop either side's changes.

## Rebase Agent Scope (MANDATORY when acting in that role)

- Force-push with `--force-with-lease` only after all conflicts are resolved.
- Any other conflict, i.e. one outside the deterministic algorithm above: report verbatim to Orchestrator; do not resolve it yourself.

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
