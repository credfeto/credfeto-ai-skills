---
name: credfeto-pre-work-healthcheck
description: Run before starting any work on an issue or PR in a repository. Verifies language/runtime prerequisites, runs the pre-commit baseline against all tracked files, and runs dotnet buildcheck in .NET repositories. Use at the start of every task, before writing any code, to ensure CI results are unambiguous.
---

# Pre-Work Health Check

Run these checks **before starting any work** on an issue or PR. Do not write code or make partial changes until every applicable check passes.

## 1. Language/Runtime Prerequisites (MANDATORY)

Verify all required languages and runtimes for the repository are installed. If any are missing, **stop** — do not scaffold code or make partial changes; ask the user to install them first.

If a required CLI tool is not found, **stop immediately and ask the user to install it**. Never:

- Search for the binary in alternative locations
- Manipulate `PATH` to try to find it
- Attempt to install it without being asked

## 2. Environment Health (MANDATORY)

If the environment is too broken to work in without first fixing infrastructure or tooling, **stop** and demand it be fixed. Do not work around broken tooling.

## 3. Pre-Commit Baseline Check (MANDATORY)

If you are resuming an existing work branch (rather than branching fresh from an up-to-date `main`), bring it up to date **before** running the baseline hook below, as three distinct, ordered steps:

1. **Fetch**: `git -C <repodir> fetch origin main` — always fetch first, regardless of whether a rebase turns out to be needed.
2. **Check**: `git -C <repodir> rev-list --count HEAD..origin/main` — a non-zero count means `origin/main` has advanced and a rebase is needed.
3. **Rebase**: only if step 2 found new commits, rebase onto `origin/main` now, resolving any conflicting version bumps by taking the latest candidate version (unless it carries a known security advisory that an older candidate doesn't). Run the build and tests once the rebase completes.

A branch just created fresh from an up-to-date `main` doesn't need this — it starts current by construction.

Then, resolve `<hooks-path>` (see "Never block by deduction" below) and run the hook against every tracked file to verify the repo is clean:

```bash
<hooks-path>/pre-commit --all-files
```

1. If the check **auto-fixes** files (e.g. trailing whitespace, end-of-file) and everything else passes: commit those fixes on a **new, dedicated branch and issue** — a clean base-point, kept separate from the branch/issue for the requested work — and mark the original work item `Blocked` until the base-fix branch is merged. Do not start the requested work on top of an unmerged, auto-mutated baseline.
2. If the check **fails** with errors that require manual fixes: fix and commit them first, then proceed with the original work.
3. If the check **still fails** after all fixing attempts:
   - For an issue: comment on the issue, label it `Blocked`, and do not start work.
   - For a PR: comment on the PR, label it `Blocked`, and do not continue work.

This ensures CI results are unambiguous — pre-existing failures are resolved before any new changes are introduced.

### Never block by deduction

Never block work based on inspecting config files and deducing that a tool might be missing. Always verify by actually running the hook:

1. Find the installed hooks path by checking `core.hooksPath` at each git config scope in order — the **first** scope where it is set is treated as sufficient; do not check the remaining scopes:
   1. `git config --system --get core.hooksPath`
   2. `git config --global --get core.hooksPath`
   3. `git config --local --get core.hooksPath` (run inside the repo)
   If none of the three scopes returns a value, the hook is **not installed**.
2. Stage your changes.
3. Run the pre-commit hook directly: `<hooks-path>/pre-commit`, using the path found in step 1.
4. Only block if the hook **actually fails** with a real error.

Inspecting `.pre-commit-config.yaml` and concluding a `language: system` tool is absent is not sufficient — the tool may be installed in a location not visible to `command -v` in the current shell context.

## 4. .NET Repository Health Check (MANDATORY when a `.csproj`, `.sln`, or `.slnx` file is present)

1. Find the solution file (prefer `*.slnx` over `*.sln`; look in the repo root and `src/`).
2. Run: `dotnet buildcheck -solution <solutionfilename>`
3. If it fails:
   - Fix all reported issues.
   - Verify with `dotnet build` and `dotnet test`.
   - Commit the fixes with a conventional commit message and push.
   - Only proceed with the original work once buildcheck passes cleanly.
4. If buildcheck still fails after all fixing attempts:
   - For an issue: add a comment and label it `Blocked` — do not start work.
   - For a PR: comment on the PR and label it `Blocked` — do not continue work.

Always invoke dotnet tools via `dotnet <toolname>` (e.g. `dotnet buildcheck`). Never search for the tool binary, add it to `PATH`, or invoke it directly as `~/.dotnet/tools/<toolname>`.

## 5. Existing Work Check (MANDATORY)

Before branching:

1. Run `gh pr list --state open --repo <owner/repo> --json number,title,author,headRefName,url` — no `--author @me` filter.
2. If any open PR's `headRefName` contains the issue number, that is prior work — resume it instead of creating a new branch.
3. For PRs authored by `app/github-actions` where all commits are yours, take ownership rather than duplicating work.
