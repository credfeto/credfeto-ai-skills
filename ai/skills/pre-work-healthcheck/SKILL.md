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

Run the pre-commit hooks against all tracked files to verify the repo is clean:

```bash
pre-commit run --all-files
```

1. If hooks **auto-fix** files (e.g. trailing whitespace, end-of-file): commit those fixes separately before starting the original work.
2. If hooks **fail** with errors that require manual fixes: fix and commit them first, then proceed with the original work.
3. If hooks **still fail** after all fixing attempts:
   - For an issue: comment on the issue, label it `Blocked`, and do not start work.
   - For a PR: comment on the PR, label it `Blocked`, and do not continue work.

This ensures CI results are unambiguous — pre-existing failures are resolved before any new changes are introduced.

If the repository has no `.pre-commit-config.yaml`, this step does not apply.

### Never block by deduction

Never block work based on inspecting config files and deducing that a tool might be missing. Always verify by actually running the hook:

1. Stage your changes.
2. Run the pre-commit hook directly: `<hooks-path>/pre-commit` (find the path with `git config --global core.hooksPath`).
3. Only block if the hook **actually fails** with a real error.

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
