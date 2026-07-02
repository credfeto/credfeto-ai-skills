---
name: credfeto-git-branch
description: Create, name, and maintain git branches — branching rules, Conventional Commits-style branch naming, rebasing against main, and resolving version conflicts in dependency manifests during merges/rebases. Use when starting new work, creating a branch, rebasing, or resolving merge conflicts.
---

# Git Branching Workflow

## Branching Rules

- All new work must be in a branch — **never commit directly to `main`**.
- Ensure `main` is up-to-date with `origin` before starting.
- Continue in the same branch until the task changes.
- Before continuing work on an existing branch, check if `origin/main` has advanced — if so, rebase first.
- Only one active branch or open PR per repository at a time; do not create another until the current one is merged and closed.
- Always use `git -C <dir> <command>` — never `cd <dir> && git <command>`.

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
2. If any open PR's `headRefName` contains the issue number, that is prior work — resume it instead of creating a new branch.

## Pushing Branches

- **Always push a new branch with `-u`**: `git -C <repodir> push -u origin <branch>`.
- Subsequent pushes on a tracked branch can use `git -C <repodir> push`.
- Never push without `-u` on the first push — without it the branch has no upstream and later `git push`/`git pull` commands will fail.

## Rebasing

- Whenever rebasing from main, take the current branch's changes, but merge the changes in from main into the current fileset.
- After the rebase completes, run the build and tests before pushing.

## Resolving Version Conflicts When Merging or Rebasing

When a merge or rebase produces conflicting versions of the same package, action, or runtime (both branches changed the version), resolve each conflicting entry individually — **never take a whole file wholesale from one side**.

This applies to every version-bearing file, including:

- Dependency manifests: `.csproj`, `Directory.Packages.props`, `packages.config`, `package.json`, `requirements.txt`
- GitHub Actions `uses:` version pins in workflows and composite actions
- Runtime and tool versions: .NET SDK (`global.json`), `dotnet-tools.json`, Node.js (`.nvmrc`, `engines`, `setup-node` versions), Python (`.python-version`, `setup-python` versions), and similar

Rules:

1. Take the **latest** of the candidate versions.
2. **Security exception**: if the latest candidate is known to be less secure than another candidate (e.g. it has a published security advisory that the other does not), take the most recent candidate that is not affected.
3. Never resolve by downgrading below every candidate, and never invent a version that appears on neither side.
4. Lock files (`package-lock.json` and similar): do not hand-merge — resolve the manifest first, then regenerate the lock file with the package manager.
5. After the merge or rebase completes, run the build and tests. If the chosen version broke the build (API changes, removed features), fix the breakage on the same branch as part of the merge work — do not downgrade to avoid the fix.

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
