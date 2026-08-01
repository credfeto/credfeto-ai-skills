---
name: credfeto-pre-work-healthcheck
description: Verify language/runtime prerequisites, run the pre-commit baseline against all tracked files, bootstrap COVERAGE.md when picking up a fresh issue, and run dotnet buildcheck in .NET repositories, before starting any work on an issue or PR. Use at the start of every task, before writing any code, to ensure CI results are unambiguous.
---

# Pre-Work Health Check

Run these checks **before starting any work** on an issue or PR. Do not write code or make partial changes until every applicable check passes.

## 1. Language/Runtime Prerequisites (MANDATORY)

Verify all required languages and runtimes for the repository are installed. If any are missing, **stop**: do not scaffold code or make partial changes; ask the user to install them first.

If a required CLI tool is not found, **stop immediately and ask the user to install it**. Never:

- Search for the binary in alternative locations
- Manipulate `PATH` to try to find it
- Attempt to install it without being asked

## 2. Environment Health (MANDATORY)

If the environment is too broken to work in without first fixing infrastructure or tooling, **stop** and demand it be fixed. Do not work around broken tooling.

## 3. Pre-Commit Baseline Check (MANDATORY)

If you are resuming an existing work branch (rather than branching fresh from an up-to-date `main`), bring it up to date **before** running the baseline hook below, as three distinct, ordered steps:

1. **Fetch**: `git -C <repodir> fetch origin main`; always fetch first, regardless of whether a rebase turns out to be needed.
2. **Check**: `git -C <repodir> rev-list --count HEAD..origin/main`; a non-zero count means `origin/main` has advanced and a rebase is needed.
3. **Rebase**: only if step 2 found new commits, rebase onto `origin/main` now. Resolve any conflicting version bumps (package, action, or runtime versions) one entry at a time, never by taking a whole file wholesale from one side, using these rules in order:
   1. Take the **latest** of the candidate versions.
   2. **Stable-over-pre-release exception**: if one candidate is a stable (release) version and the other is a pre-release (alpha/beta/rc/preview/dev build, etc.), take the stable candidate even if the pre-release has a nominally higher version number. Only take a pre-release if every candidate is a pre-release, in which case take the latest of them.
   3. **Security exception**: if the latest candidate is known to be less secure than another candidate (e.g. it has a published security advisory that the other does not), take the most recent candidate that is not affected.
   4. Never resolve by downgrading below every candidate, and never invent a version that appears on neither side.
   5. Lock files (`package-lock.json` and similar): do not hand-merge; resolve the manifest first, then regenerate the lock file with the package manager.

   These five rules are a deterministic algorithm: for every conflicting entry there is exactly one correct resolution. Apply it and continue; do not stop the rebase to ask for confirmation on a conflict this algorithm resolves unambiguously, and do not post a PR/issue comment asking someone to confirm the choice. Only stop and ask when a conflict genuinely falls outside it, for example the same package bumped to two unrelated versions with no clear "latest" (divergent major versions), or a security trade-off with no candidate that is both latest and unaffected.

   Run the build and tests once the rebase completes. If the chosen version broke the build (API changes, removed features), fix the breakage on the same branch as part of the merge work; do not downgrade to avoid the fix. No coverage re-baseline step is needed here: coverage is always measured against `origin/main`'s live `COVERAGE.md`, so a plain rebase cannot make it stale.

   **If the rebase itself produces a conflict in `COVERAGE.md`**: do not hand-merge the percentages; it is generated content, not hand-authored. Take `main`'s copy:

   ```bash
   git -C <repodir> checkout --ours -- COVERAGE.md
   git -C <repodir> add COVERAGE.md
   ```

   (During a rebase, `--ours` means the branch being rebased *onto*, i.e. `origin/main`, the reverse of a merge's usual meaning.) Continue the rebase. Once it completes and the build/test step above passes, re-measure coverage (see step 4 below) against the rebased tree and commit the fresh `COVERAGE.md` as part of the same rebase work; do not leave `main`'s stale copy in place.

A branch just created fresh from an up-to-date `main` doesn't need this; it starts current by construction.

Then, resolve `<hooks-path>` (see "Never block by deduction" below) and run the hook against every tracked file to verify the repo is clean:

```bash
<hooks-path>/pre-commit --all-files
```

1. If the check **auto-fixes** files (e.g. trailing whitespace, end-of-file) and everything else passes: commit those fixes on a **new, dedicated branch and issue**, a clean base-point kept separate from the branch/issue for the requested work, and mark the original work item `Blocked` until the base-fix branch is merged. Do not start the requested work on top of an unmerged, auto-mutated baseline.
2. If the check **fails** with errors that require manual fixes: fix and commit them first, then proceed with the original work.
3. If the check **still fails** after all fixing attempts:
   - For an issue: comment on the issue, label it `Blocked`, and do not start work.
   - For a PR: comment on the PR, label it `Blocked`, and do not continue work.

This ensures CI results are unambiguous; pre-existing failures are resolved before any new changes are introduced.

### Never block by deduction

Never block work based on inspecting config files and deducing that a tool might be missing. Always verify by actually running the hook:

1. Find the installed hooks path by checking `core.hooksPath` at each git config scope in order: the **first** scope where it is set is treated as sufficient; do not check the remaining scopes:
   1. `git config --system --get core.hooksPath`
   2. `git config --global --get core.hooksPath`
   3. `git config --local --get core.hooksPath` (run inside the repo)
   If none of the three scopes returns a value, the hook is **not installed**.
2. Stage your changes.
3. Run the pre-commit hook directly: `<hooks-path>/pre-commit`, using the path found in step 1.
4. Only block if the hook **actually fails** with a real error.

Inspecting `.pre-commit-config.yaml` and concluding a `language: system` tool is absent is not sufficient; the tool may be installed in a location not visible to `command -v` in the current shell context.

## 4. COVERAGE.md Bootstrap for New Issues (MANDATORY)

Only when picking up a **new issue** by branching fresh from an up-to-date `main` (not resuming an existing branch): once the baseline hook in step 3 passes cleanly, check whether `COVERAGE.md` exists at the repo root.

- **If it exists**, nothing further is needed: coverage is always compared against `origin/main`'s live copy later in the workflow, so there is no per-branch capture step and nothing to refresh here.
- **If it does not exist**, collect it now, while still on `main`, before creating the work branch:
  1. Measure the overall line-coverage percentage for each orchestrated language actually present in the repo:
     - **.NET**: collect each `<AssemblyName>.Tests` project's coverage, generate per-assembly `reportgenerator` reports, then one combined report requesting `-reporttypes:"Html;JsonSummary"`, and read the overall figure with `jq '.summary.linecoverage' {repo-root}/coverage/combined/Summary.json`. Skip .NET entirely if the repo has no `*.Tests` project.
     - **Node**: pinned as Vitest with `@vitest/coverage-v8`; run `npx vitest run --coverage` with the `json-summary` reporter configured, then `jq '.total.lines.pct' coverage/coverage-summary.json`. Skip if the repo has no `package.json` with a configured test runner.
     - **Python**: pinned as `coverage.py` via `pytest`; run `coverage run -m pytest` then `coverage report --format=total` (prints only the overall percentage). Skip if the repo has no Python test suite.
     - **Shell**: always excluded; never attempt to measure it.
  2. Write `COVERAGE.md` at the repo root, including every one of the four languages as a section even when skipped (`n/a (no code)` for a language with no code/tests present; `excluded` for Shell, always):

     ```text
     # Coverage

     Generated by the AI Coverage phase. Do not edit by hand.

     ## .NET

     | Project | Line Coverage |
     | --- | --- |
     | Credfeto.Foo | 82.1% |
     | **Overall (.NET)** | **80.3%** |

     ## Node

     | Package | Line Coverage |
     | --- | --- |
     | **Overall (Node)** | 91.4% |

     ## Python

     | Package | Line Coverage |
     | --- | --- |
     | **Overall (Python)** | 74.3% |

     ## Shell

     excluded

     ---

     Captured at commit `<sha>` on <ISO-8601 date>.
     ```

     `<sha>` is the commit the numbers were measured against.
  3. Create the work branch as normal and commit the resulting `COVERAGE.md` as its **first commit**, before starting the requested work. No separate branch or issue is needed for this bootstrap commit, unlike the pre-commit auto-fix case above: only one branch/PR is allowed open per repo at a time, so there is no concurrent-bootstrap race to isolate against.
  4. `COVERAGE.md` will be overwritten again later in the same PR with the branch's live numbers once coverage is next measured; expect two commits touching the file over the branch's lifetime, that is not a conflict.

## 5. .NET Repository Health Check (MANDATORY when a `.csproj`, `.sln`, or `.slnx` file is present)

1. Find the solution file (prefer `*.slnx` over `*.sln`; look in the repo root and `src/`).
2. Run: `dotnet buildcheck -solution <solutionfilename>`
3. If it fails:
   - Fix all reported issues.
   - Verify with `dotnet build` and `dotnet test`.
   - Commit the fixes with a conventional commit message and push.
   - Only proceed with the original work once buildcheck passes cleanly.
4. If buildcheck still fails after all fixing attempts:
   - For an issue: add a comment and label it `Blocked`; do not start work.
   - For a PR: comment on the PR and label it `Blocked`; do not continue work.

Always invoke dotnet tools via `dotnet <toolname>` (e.g. `dotnet buildcheck`). Never search for the tool binary, add it to `PATH`, or invoke it directly as `~/.dotnet/tools/<toolname>`.

## 6. Existing Work Check (MANDATORY)

Before branching:

1. Run `gh pr list --state open --repo <owner/repo> --json number,title,author,headRefName,url`, no `--author @me` filter.
2. If any open PR's `headRefName` contains the issue number, that is prior work; resume it instead of creating a new branch.
3. For any PR authored by `app/github-actions` (github is configured to auto-create PRs from pushed branches; these appear bot-authored but the commits are yours), verify the commit authors before taking ownership: `gh pr view <n> --repo <owner/repo> --json commits --jq '.commits[].authors[].login'`. If **all commits** are from your account, take ownership rather than duplicating work: update the title/body to match the proper format, add yourself as assignee, and treat it as your active PR. If commits are from multiple authors (e.g. you plus a human or Copilot), do **not** take over; leave the PR as-is.
4. Do **not** create a new branch or PR for the same issue; that would be duplicate work. If a duplicate pair already exists (a bot-created PR and one you authored yourself, for the same issue or branch): keep whichever has the more complete body and later review activity, and close the other with a comment explaining which PR supersedes it.
