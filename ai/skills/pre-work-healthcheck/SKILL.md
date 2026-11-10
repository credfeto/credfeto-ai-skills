---
name: credfeto-pre-work-healthcheck
description: Verify language/runtime prerequisites, run the pre-commit baseline against all tracked files, bootstrap COVERAGE.md when picking up a fresh issue, run dotnet buildcheck in .NET repositories, and re-check open branches/PRs for compliance whenever an instruction file changes, before starting any work on an issue or PR. Use at the start of every task, before writing any code, to ensure CI results are unambiguous.
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

If you are resuming an existing work branch (rather than branching fresh from an up-to-date `main`), bring it up to date **before** running the baseline check below, as three distinct, ordered steps. If this rebase procedure runs `pre-commit-check` (see step 3 below), that already satisfies the baseline check further down this section; do not run it a second time.

1. **Fetch**: `git -C <repodir> fetch origin main`; always fetch first, regardless of whether a rebase turns out to be needed.
2. **Check**: `git -C <repodir> rev-list --count HEAD..origin/main`; a non-zero count means `origin/main` has advanced and a rebase is needed.
3. **Rebase**: only if step 2 found new commits, rebase onto `origin/main` now. Resolve any conflicting version bumps (package, action, or runtime versions) one entry at a time, never by taking a whole file wholesale from one side. This covers every version-bearing file: dependency manifests (`.csproj`, `Directory.Packages.props`, `packages.config`, `package.json`, `requirements.txt`), GitHub Actions `uses:` version pins in workflows and composite actions, and runtime and tool versions (.NET SDK in `global.json`, `dotnet-tools.json`, Node.js in `.nvmrc`, `engines` or `setup-node` versions, Python in `.python-version` or `setup-python` versions, and similar). Use these rules in order:
   1. Take the **latest** of the candidate versions.
   2. **Stable-over-pre-release exception**: if one candidate is a stable (release) version and the other is a pre-release (alpha/beta/rc/preview/dev build, etc.), take the stable candidate even if the pre-release has a nominally higher version number. Only take a pre-release if every candidate is a pre-release, in which case take the latest of them.
   3. **Security exception**: if the latest candidate is known to be less secure than another candidate (e.g. it has a published security advisory that the other does not), take the most recent candidate that is not affected.
   4. Never resolve by downgrading below every candidate, and never invent a version that appears on neither side.
   5. Lock files (`package-lock.json` and similar): do not hand-merge; resolve the manifest first, then regenerate the lock file with the package manager.

   These five rules are a deterministic algorithm: for every conflicting entry there is exactly one correct resolution. Apply it and continue; do not stop the rebase to ask for confirmation on a conflict this algorithm resolves unambiguously, and do not post a PR/issue comment asking someone to confirm the choice. Only stop and ask when a conflict genuinely falls outside it, for example the same package bumped to two unrelated versions with no clear "latest" (divergent major versions), or a security trade-off with no candidate that is both latest and unaffected.

   When the branch has already been pushed, rebasing rewrites its history, so pushing it needs a force-push. That is allowed only for a pure rebase that passes every check below, because a force-push to a shared branch, or over commits someone else pushed, destroys their work. This applies to every role that rebases a pushed branch, including the Rebase Agent.
   - Before rebasing, refuse `main`, `master`, `develop`, `release/*` and any other shared branch: only a personal feature or topic branch may be rebased and force-pushed.
   - Before rebasing, fetch the branch (`git -C <repodir> fetch origin <branch>`) and confirm that local HEAD equals remote HEAD: `git -C <repodir> rev-parse refs/heads/<branch>` must print the same SHA as `git -C <repodir> rev-parse refs/remotes/origin/<branch>`, because a difference means the local branch is not what was pushed, so the force-push would not be a pure rebase of the remote branch and could drop commits pushed from elsewhere.
   - Push with `git -C <repodir> push --force-with-lease origin <branch>` only. Never use plain `--force` (or `-f`), because only the lease refuses to overwrite commits pushed since the fetch.
   - If any check above fails, or the push is rejected, stop and ask the human, quoting the output verbatim. Do not retry the push and do not fall back to plain `--force`.

   Run the build and tests once the rebase completes. If the chosen version broke the build (API changes, removed features), fix the breakage on the same branch as part of the merge work; do not downgrade to avoid the fix. Then run `pre-commit-check` against all tracked files, in the background, and wait for its completion notification, judging it by its exit code before continuing (0 is a pass, anything else a failure; see the long-running-commands skill for the waiting rules and the 30-minute deadline). Do this after every rebase in a session, not only the first. The Rebase Agent does not run this check itself: the Orchestrator runs it as the Post-Rebase Check once the rebase is complete, or the role that performed the rebase runs it directly. When the Orchestrator runs this check, it never edits files itself: it hands every fix, commit and push to the fix route (Code Fixer, Code Tester, Committer, PR Submitter, CI Monitor).
   - Fix every issue `pre-commit-check` reports, including issues that were already present before the rebase, because it covers the whole repository. Re-run it after each round of fixes and repeat until it reports no issues. Do not continue with any other work while issues remain, and do not suppress or weaken a check to make it pass.
   - Commit each fix as its own commit on the current branch, separate from the rebase and from fixes to other constructs, then continue.
   - Only for an issue that is genuinely fatal (pre-commit cannot possibly be made to pass, for example a required external tool is missing from the environment and cannot be installed, or the cause is infrastructure outside the repo's control, or the only fix is a suppression, skip or exclusion that needs authorisation): comment on the issue/PR with the verbatim output and label it `Blocked`, and do not continue work. Difficulty is not a reason to escalate.
   - If it only auto-fixes files (e.g. trailing whitespace) with everything else passing: commit those fixes on the current branch in their own commit.

   No coverage re-baseline step is needed here: coverage is always measured against `origin/main`'s live `COVERAGE.md`, so a plain rebase cannot make it stale.

   **If the rebase itself produces a conflict in `COVERAGE.md`**: do not hand-merge the percentages; it is generated content, not hand-authored. Take `main`'s copy:

   ```bash
   git -C <repodir> checkout --ours -- COVERAGE.md
   git -C <repodir> add COVERAGE.md
   ```

   (During a rebase, `--ours` means the branch being rebased *onto*, i.e. `origin/main`, the reverse of a merge's usual meaning.) Continue the rebase. Once it completes and the build/test step above passes, re-measure coverage (see step 4 below) against the rebased tree and commit the fresh `COVERAGE.md` as part of the same rebase work; do not leave `main`'s stale copy in place.

A branch just created fresh from an up-to-date `main` doesn't need this; it starts current by construction.

Run `pre-commit-check` only when starting work on a new branch (the baseline check below), after a rebase, or when explicitly asked to, whether in an interactive session or in an issue. There are no other times to run it: `git commit` runs the same hooks automatically, so running it separately before a commit only repeats work the commit does anyway. When a commit fails on a hook, fix the cause and retry the commit. The re-runs inside the rebase check are part of that check, not an extra trigger.

The Code Tester, Code Fixer and Code Writer roles are never a trigger: they never run `pre-commit-check` and never ask another role to run it. A hook failure on `git commit` goes back through the Committer. A role never runs two unbounded commands (build, test suite, `pre-commit-check`, commit) at the same time; it runs them one after another.

If you are starting a fresh branch from an up-to-date `main`, run the baseline check now, before starting any work on an issue or PR, to verify the repo is clean. Resuming an existing branch that needed no rebase does not run it, because the commit hook covers it:

```bash
pre-commit-check
```

**Always run this check in the background**: it is more likely than not to take a while to run, not an exception case to spot and handle specially. Backgrounding it does not mean walking away from it: you MUST then wait for it to finish and judge it by its exit code, in this same session, before doing anything else that depends on it. This is not optional; see the long-running-commands skill for the waiting rules and the 30-minute deadline. A sub-agent may end its turn while the check runs, but must never report or hand back before its completion notification arrives. The main session of an unattended run must **not** end its turn while the check runs, because a fresh, single-phase invocation that is never resumed starts with no memory of the wait, and the backgrounded check is killed when the run ends, so the result is never seen. If your own session genuinely is interactive and resumable, confirm that explicitly before treating "come back to this later" as safe; absent that confirmation, assume it is not.

1. If the check **auto-fixes** files (e.g. trailing whitespace, end-of-file) and everything else passes: commit those fixes in **their own commit** on the work branch before any new work, separate from the requested work, then proceed. If no work branch exists yet (for example a new issue still waiting for plan approval), discard the auto-fixes instead, only in files that had no uncommitted changes before the check ran (`git -C <dir> checkout -- <files>`, after running `git -C <dir> status` first, as the check regenerates them), and re-run the check once the work branch is created, because committing on `main` is forbidden. Do not open a separate branch or issue for them or add `Blocked`, because only one branch/PR is open per user per repository at a time, so a separate base-fix branch could never be opened alongside the work; the dedicated commit keeps the baseline fix distinguishable from the work in CI and review.
2. If the check **fails** with errors that require manual fixes: fix and commit them first, then proceed with the original work. Pre-commit and its component tools are improved incrementally precisely by encountering and fixing the problems they surface, so fixing a failure is part of the current work. Do not stop, escalate or add `Blocked` merely because the failure is unexpected, was not present originally, also fails on main, or requires changes outside the files you set out to edit (however many), including the pre-commit configuration or a component tool's own rules or config. The fix must be a genuine fix, not a suppression, skip or exclusion, unless separately authorised. If a component tool's fix is a package change (adding, changing, or removing a package reference), this does not automatically require the standard new-package approval-and-wait: follow the pre-commit/component-tool package-change conflict-resolution path instead, which still falls back to approval-and-wait if its own security review finds a genuine blocker.
3. If the check **still fails** after all fixing attempts and it is genuinely fatal (pre-commit cannot possibly be made to pass, for example a required external tool is missing from the environment and cannot be installed, or the cause is infrastructure outside the repo's control, or the only fix is a suppression, skip or exclusion that needs authorisation; otherwise keep fixing, as step 2 requires), cite that condition and:
   - For an issue: comment on the issue, label it `Blocked`, and do not start work.
   - For a PR: comment on the PR, label it `Blocked`, and do not continue work.

This ensures CI results are unambiguous; pre-existing failures are resolved before any new changes are introduced.

### Never block by deduction

Never block work based on inspecting config files and deducing that a tool might be missing. Always verify empirically: stage your changes and run `git commit` as normal; the pre-commit hook runs automatically and aborts the commit cleanly if it fails, leaving your staged changes intact. Only block if that actually fails with a real error.

Inspecting `.pre-commit-config.yaml` and concluding a `language: system` tool is absent is not sufficient; the tool may be installed in a location not visible to `command -v` in the current shell context. This carve-out also covers a required CLI tool that appears missing under [Language/Runtime Prerequisites](#1-languageruntime-prerequisites-mandatory) above: do not conclude a pre-commit hook tool is absent just because `command -v` finds nothing in the current shell; verify by staging and committing as described here before blocking.

### Pre-Commit Hook Known Incompatibilities

- **dotenv-linter**: use `entry: dotenv-linter check`; v3.x requires the `check` subcommand before the filename.

## 4. COVERAGE.md Bootstrap for New Issues (MANDATORY)

Only when picking up a **new issue** by branching fresh from an up-to-date `main` (not resuming an existing branch): once the baseline hook in step 3 passes (or only auto-fixes, handled as above), check whether `COVERAGE.md` exists at the repo root. A missing `COVERAGE.md` means the coverage ratchet has never been applied to this repo, not that it can be skipped: if you are making changes, or have already made changes, to a repo without one, you **must** create it now and keep it maintained thereafter, regardless of whether the requested work touches code coverage at all. Do not treat this as a nice-to-have or defer it to a later PR; skipping it leaves the repo permanently ungated.

- **If it exists**, nothing further is needed: coverage is always compared against `origin/main`'s live copy later in the workflow, so there is no per-branch capture step and nothing to refresh here.
- **If it does not exist**, collect it now, while still on `main`, before creating the work branch:
  1. Measure the overall line-coverage percentage for each orchestrated language actually present in the repo:
     - **.NET**: when the `build-dotnet` MCP server lists its `coverage` tool, run that tool instead and take the figures from its `job_result` (reading a per-assembly figure the table needs from the job's full log, whose path `job_result` gives, rather than re-running coverage), never measuring the same branch both ways. Otherwise collect each `<AssemblyName>.Tests` project's coverage, generate per-assembly `reportgenerator` reports, then one combined report requesting `-reporttypes:"Html;JsonSummary"`, and read the overall figure with `jq '.summary.linecoverage' {repo-root}/coverage/combined/Summary.json`. Skip .NET entirely if the repo has no `*.Tests` project.
     - **Node**: pinned as Vitest with `@vitest/coverage-v8`; run `npx vitest run --coverage` with the `json-summary` reporter configured (alongside whatever other reporters the repo already uses), then `jq '.total.lines.pct' coverage/coverage-summary.json`. If the repository's `package.json` defines a `test:coverage` script, that script takes precedence: run `npm ci` and then `npm run test:coverage` from the repository root with no arguments, `--prefix`, `cd` or redirects, and read `coverage/coverage-summary.json`. Skip if the repo has no `package.json` with a configured test runner.
     - **Python**: pinned as `coverage.py` via `pytest`; run `coverage run -m pytest` then `coverage report --format=total` (prints only the overall percentage). Skip if the repo has no Python test suite.
     - **Shell**: always excluded; never attempt to measure it.
  2. Write `COVERAGE.md` at the repo root, including every one of the four languages as a section even when skipped (`n/a (no code)` for a language with no code/tests present; `excluded` for Shell, always, or for another language where every production assembly/package in it is deliberately marked to exclude it from coverage instrumentation because the repo itself is test-support/test-infrastructure; record a one-line rationale beneath `excluded` in that case):

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

     `<sha>` is the commit the numbers were measured against. The file records only the coverage figures (the component rows, the Overall rows and the `<sha>` line); never record the command, tools, flags or runner used to measure them.
  3. Create the work branch as normal and commit the resulting `COVERAGE.md` in **its own commit**, before starting the requested work. No separate branch or issue is needed for this bootstrap commit, as for the pre-commit auto-fix case above: only one branch/PR is allowed open per user per repository at a time, so there is no concurrent-bootstrap race to isolate against.
  4. `COVERAGE.md` will be overwritten again later in the same PR with the branch's live numbers once coverage is next measured; expect two commits touching the file over the branch's lifetime, that is not a conflict.

## 5. .NET Repository Health Check (MANDATORY when a `.csproj`, `.sln`, or `.slnx` file is present)

1. Find the solution file (prefer `*.slnx` over `*.sln`; look in the repo root and `src/`).
2. Run the `buildcheck` tool of the `build-dotnet` MCP server when the server lists it; otherwise run: `dotnet buildcheck -solution <solutionfilename>`
3. If it fails:
   - Fix all reported issues. If a fix is a package change (adding, changing, or removing a package reference), this does not automatically require the standard new-package approval-and-wait: follow the pre-commit/component-tool package-change conflict-resolution path instead, which still falls back to approval-and-wait if its own security review finds a genuine blocker.
   - Verify with the `build` and `test` tools of the `build-dotnet` MCP server, or with `dotnet build` and `dotnet test` when the server lists no tool for them; the raw commands are each run in the background and one at a time.
   - Commit the fixes with a conventional commit message and push.
   - Only proceed with the original work once buildcheck passes cleanly.
4. If buildcheck still fails after all fixing attempts:
   - For an issue: add a comment and label it `Blocked`; do not start work.
   - For a PR: comment on the PR and label it `Blocked`; do not continue work.

Always invoke dotnet tools via `dotnet <toolname>` (e.g. `dotnet buildcheck`). Never search for the tool binary, add it to `PATH`, or invoke it directly as `~/.dotnet/tools/<toolname>`.

Use the `build-dotnet` MCP tools only when the server lists the tool for the task; otherwise use the raw command. Never run the same build or test both ways: a job's `job_result` is the result, so do not repeat it with the raw command to confirm it, and do not run the raw command while an MCP job is running. An MCP job is a long-running command, so run only one at a time. Every tool except `detect`, `job_status` and `job_result` starts a job and returns its id at once: wait for it by calling `job_status` once, then about every 30 to 60 seconds, never in a tight loop or a shell wait loop, and when the state is no longer running read `job_result` and judge the job by its per-step exit codes, test counts and failing tests. Do not wait for a job with `cfwf task wait` or a completion notification. Before handing back, wait for every job you started to finish.

All projects must be added to the solution file (`.slnx` or `.sln`).

If a build fails because `$(SolutionDir)` is undefined (e.g. imports guarded by `Exists('$(SolutionDir)...')` are silently skipped, leading to errors such as `NU5017`), fix it by ensuring the solution's `src/` directory has a `Directory.Build.props` that sets a fallback:

```xml
<Project>
    <PropertyGroup>
        <SolutionDir Condition="'$(SolutionDir)' == ''">$(MSBuildThisFileDirectory)</SolutionDir>
    </PropertyGroup>
</Project>
```

This makes `$(SolutionDir)` resolve correctly in solution-less build contexts (e.g. BenchmarkDotNet host processes, `dotnet watch`, direct project builds) without changing any project files.

## 6. Existing Work Check (MANDATORY)

Before branching:

1. Run `cfwf pr list --repo <owner/repo>`, which lists every open PR, whoever authored it.
2. If any open PR's `headRefName` contains the issue number, that is prior work; resume it instead of creating a new branch.
3. For any PR authored by `app/github-actions` (github is configured to auto-create PRs from pushed branches; these appear bot-authored but the commits are yours), verify the commit authors before taking ownership: `cfwf pr view --repo <owner/repo> --pr <n> --field commit-authors`. If **all commits** are from your account, take ownership rather than duplicating work: update the title/body to match the proper format, add yourself as assignee, and treat it as your active PR. If commits are from multiple authors (e.g. you plus a human or Copilot), do **not** take over; leave the PR as-is.
4. Do **not** create a new branch or PR for the same issue; that would be duplicate work. If a duplicate pair already exists (a bot-created PR and one you authored yourself, for the same issue or branch): keep whichever has the more complete body and later review activity, and close the other with a comment explaining which PR supersedes it.
5. This only catches work that already has an open PR. A branch may have been pushed and then abandoned before a PR was ever opened (e.g. a prior session died mid-task), so also check for a matching branch directly, using the `<type>/<issue-number>-<name>` naming convention:

   ```bash
   git -C <dir> ls-remote --heads origin "*/<issue-number>-*"
   ```

   - No match: branch fresh from `main` as normal.
   - Match found: fetch it and compare against `main`:

     ```bash
     git -C <dir> fetch origin <branch>
     git -C <dir> rev-list --count origin/main..origin/<branch>
     ```

     - `0` (not ahead of `main`): branch fresh from `main` as normal.
     - `>0`: check it out and continue from there instead of branching again, rebasing first (see step 3 above) if `origin/main` has advanced.

## 7. Rules Compliance for In-Flight Work (MANDATORY)

Whenever an instruction file is added or updated, re-evaluate all open branches and PRs against the new rules before continuing other work. Fix any non-compliance found; treat it the same as a CI failure.
