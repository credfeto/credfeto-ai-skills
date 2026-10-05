---
name: credfeto-pr-review-loop
description: Run the simplify, code-review, security-review, and coverage-ratchet passes on a pull request after all code changes are pushed and CI passes, before enabling auto-merge, including the fix route and changelog-correction step and Pattern Sweep folded into each fix, how each review phase can exit without blocking once it stops finding anything new, how a static analyzer's rule always wins over a review suggestion, how the coverage ratchet gates on whole-repo per-language coverage rather than just the diff and blocks when it judges the gap unlikely to close, how the PR is marked ready and auto-merge enabled only once checks have run after that, and how to mark an environment-caused block for later auto-clearing. Use after CI is green on a PR and before marking it ready or enabling auto-merge.
---

# PR AI Review Loop

After all code changes are pushed and all required CI checks pass, run these phases in order **before** enabling auto-merge on the PR. A required check that skips while the PR is a draft counts as passed here, but it has not run yet: it first runs once Phase E marks the PR ready. Phases B, C, and D each have their own configurable maximum number of rounds (`MAX_CODE_REVIEW_ITERATIONS`, `MAX_SECURITY_REVIEW_ITERATIONS`, `MAX_COVERAGE_ITERATIONS` respectively). Phase A uses its own, separate budget (see below).

The Orchestrator runs each review and judges convergence and thrash, but never implements directly: it hands every file change, commit and push to the fix route below.

## The Fix Route

Every fix the loop needs runs: Code Fixer (or Code Writer, when the step names it) → Code Tester → Changelog (correction) → Committer → PR Submitter → CI Monitor. It drops the Pre-Work Baseline Check, because that check already ran when work on the PR began, and Code Reviewer, because the loop's next phase or round reviews the change anyway. Changelog (correction) runs against the resulting diff, and `CHANGELOG.md` is committed separately if the entry changed.

- In an interactive session, after each push the loop makes, hand CI to CI Monitor, stating the run mode and the phase and step to resume at, and pause the loop until CI Monitor returns, because nothing else would watch that run or return control to the loop. CI Monitor's all-pass rule then decides whether the loop resumes there or restarts at Phase A.
- An unattended run carries on within the loop without waiting, because the PR stays in draft with auto-merge off until Phase E, and Code Fixer and CI Debugger turn auto-merge off and convert to draft before any later fix, so GitHub cannot merge a fix the loop has not reviewed.

## Phase A: Simplify (up to `MAX_SIMPLIFY_ITERATIONS` rounds, with a separate `SIMPLIFY_THRASH_LIMIT`)

1. Update the workflow board to **AI Simplify**, if one is configured (see [Updating a Workflow Board](#updating-a-workflow-board) below).
2. Have Code Fixer run `/simplify` against the diff and keep its edits. `/simplify` applies reuse, simplification, efficiency, and altitude cleanups directly rather than just reporting them, so it has to run in the role that edits files, not in the Orchestrator. Code Fixer also applies IDE MCP code analysis to the modified files (see the ide-mcp-code-analysis skill for the full best-effort and reporting procedure).
3. If the simplify pass changed any files: send the edits through the rest of the fix route, then return to step 2 to re-run against the resulting diff.
4. Once the simplify pass makes no further changes: have Code Fixer run a Pattern Sweep for each construct in the net Phase A diff (the commits since step 1), not per round, since rounds may revert each other and each sweep would widen the next round's diff. A change with no repeatable construct (a local rename or restructuring) has nothing to sweep. If the sweep changed files: send it through the fix route as in step 3, then proceed to Phase B instead of returning to step 2 (Phase B re-covers the swept code).
5. Simplify has its own iteration budget, kept deliberately separate from Phases B-D's budgets, because it is expected to run more rounds and give up without blocking:
   - Track each round's diff size (lines changed by that round's simplify commit) against the previous round's.
   - Once `SIMPLIFY_THRASH_LIMIT` rounds have run, if the current round is thrashing (its diff is flat or larger than the previous round's, i.e. not shrinking): give up immediately, even though `MAX_SIMPLIFY_ITERATIONS` has not been reached.
   - Otherwise, keep re-running up to `MAX_SIMPLIFY_ITERATIONS` rounds total; once that hard cap is reached without converging to no changes, give up regardless of whether the diff was still shrinking.
   - Either way, giving up means: post a PR comment noting that simplify did not converge, run step 4 in full (the sweep and its trip through the fix route) on the diff as it currently stands, then proceed to Phase B. **Do not add `Blocked` and do not stop**: non-convergence in Phase A never blocks the PR, because Phase B's code-review pass re-covers the same reuse/simplification/efficiency categories as a safety net.

## Phase B: Code Review (up to `MAX_CODE_REVIEW_ITERATIONS` rounds)

1. Update the workflow board to **AI Review**, if configured.
2. Run `/code-review --comment`. This intentionally re-covers the reuse/simplification/efficiency categories Phase A's `/simplify` already applied (`/simplify` fixes them silently; this step verifies nothing was missed) and separately checks correctness, which `/simplify` does not. Security and compliance are not covered here; they remain Phase C's job. Also apply IDE MCP code analysis to the modified files. Expect this step to usually find nothing in the categories Phase A already handled.
3. If no findings were posted: proceed to Phase C.
4. Otherwise, judge convergence from the PR's history of prior code-review comments: are this round's findings substantively new/distinct, or substantially a repeat of findings already reported (and left unresolved, or fixed and now recurring) in an earlier round? `MIN_REVIEW_CONVERGENCE_ROUNDS` must be set below `MAX_CODE_REVIEW_ITERATIONS`, otherwise the round-cap branch below always fires first and the non-blocking exit can never trigger.
   - If `MAX_CODE_REVIEW_ITERATIONS` rounds have already run and findings remain, whether or not this round's findings are themselves new: post a PR comment listing the unresolved findings, add the `Blocked` label, and **stop**:

     ```bash
     gh pr edit <number> --repo <owner/repo> --add-label Blocked
     ```

   - Otherwise, if substantially repeating a prior round (not converging) AND at least `MIN_REVIEW_CONVERGENCE_ROUNDS` rounds have now run: post a PR comment summarising the unresolved findings and stating that code review is not converging, advance the board to **AI Security Review** if configured, post a one-line status comment, then proceed to Phase C. **Do not add `Blocked`**: this means no new correctness issues are surfacing, not that a known one is safe to ignore; the posted comment carries the unresolved findings forward to human review.
   - Otherwise (substantively new findings, or a repeat but fewer than `MIN_REVIEW_CONVERGENCE_ROUNDS` rounds have run so far, so one failed fix attempt is not yet enough evidence to give up, and the round cap has not been reached): hand the findings, grouped by construct, to Code Fixer through the fix route, one fix change set per construct, each with a Pattern Sweep (a finding that only re-reports the swept construct in files a sweep touched is not substantively new for the convergence judgment above; a new bug in those files is). Once the route has pushed, return to step 2.

## Conflict Resolution: Simplify/Code Review vs. Static Analyzer

If a change proposed by `/simplify` (Phase A) or a finding raised by `/code-review` (Phase B) would conflict with a rule enforced by the project's build-time static analyzer stack, or by `FunFair.CodeAnalysis`, **the static analyzer's rule always wins**: do not apply the conflicting simplify/code-review suggestion, and keep the analyzer-compliant code as-is.

## Phase C: Security Review (up to `MAX_SECURITY_REVIEW_ITERATIONS` rounds)

This phase mirrors Phase B exactly, substituting security-review for code-review; keep both in sync when editing either.

1. Update the workflow board to **AI Security Review**, if configured.
2. Run `/security-review`. Also apply IDE MCP code analysis to the modified files.
3. If no findings are reported: proceed to Phase D.
4. Otherwise, judge convergence from the PR's history of prior security-review comments, the same way as Phase B step 4 above (`MIN_REVIEW_CONVERGENCE_ROUNDS` must again be set below `MAX_SECURITY_REVIEW_ITERATIONS`):
   - If `MAX_SECURITY_REVIEW_ITERATIONS` rounds have already run and findings remain, whether or not this round's findings are themselves new: post a PR comment listing the unresolved findings, add the `Blocked` label, and **stop**.
   - Otherwise, if substantially repeating a prior round AND at least `MIN_REVIEW_CONVERGENCE_ROUNDS` rounds have now run: post a PR comment summarising the unresolved findings and stating that security review is not converging, advance the board to **AI Coverage** if configured, post a one-line status comment, then proceed to Phase D. **Do not add `Blocked`**, for the same reason as Phase B's equivalent exit.
   - Otherwise (substantively new, or a repeat but fewer than `MIN_REVIEW_CONVERGENCE_ROUNDS` rounds have run so far, and the round cap has not been reached): post findings as a PR comment if not already inline, then hand the findings, grouped by construct, to Code Fixer through the fix route, one fix change set per construct, each with a Pattern Sweep (a finding that only re-reports the swept construct in files a sweep touched is not substantively new for the convergence judgment above; a new bug in those files is). Once the route has pushed, return to step 2.

## Phase D: AI Coverage (up to `MAX_COVERAGE_ITERATIONS` rounds)

This phase is a whole-repo ratchet: each orchestrated language's overall line-coverage percentage on the PR branch must be at least that language's percentage on `main`, compared against a baseline committed to `main` itself (no external coverage service). It gates on the whole repo's per-language coverage, not just the lines the PR's own diff touches; it exists to catch a deleted test or a refactor that drops coverage of code the diff never touched, which the diff-coverage check done by Code Tester would miss.

1. Update the workflow board to **AI Coverage**, if configured.
2. Run the coverage ratchet decision procedure:
   1. If every file changed on the branch (relative to its merge-base with `main`) falls into a non-code category (dependency-manifest/version-pin bumps, CI workflow YAML beyond version pins, SQL, shell scripts, Dockerfiles and Docker Compose files, or documentation-only changes), skip straight to step 5 without measuring anything; nothing that changed could have moved any language's coverage.
   2. Fetch `origin/main` fresh (always; do not rely on a fetch from earlier in the session) and read its committed coverage-baseline file, `COVERAGE.md` at the repo root, without checking it out (`git show origin/main:COVERAGE.md`). If it does not exist yet, this is a first-time bootstrap: there is no baseline to compare against, so treat the gate as passed and continue to step 5.
   3. For each orchestrated language with a real baseline figure in that file (not `n/a` or `excluded`), measure that language's current overall line coverage on the branch's working tree, producing both the per-component rows and the Overall figure (see [Measuring Coverage and the Baseline File](#measuring-coverage-and-the-baseline-file) below).
   4. Compare branch vs. baseline **overall** coverage per language (never blended across languages, and never gated on a single project/component dipping while its language's overall holds or improves; component rows are recorded but never gate): any language whose branch overall is below its baseline overall fails the gate.
   5. **On success**: have Code Writer (docs only) write or overwrite `COVERAGE.md` on the branch with the numbers just measured (or the branch's current measurement, in the skip/bootstrap cases) and send it through the fix route without Code Tester or Changelog (correction), resuming at Phase E, because the Orchestrator measures but never edits or commits itself, the coverage was measured moments ago, and a coverage figure is not a change the changelog records. Move the board to **Human Review**, post a one-line status comment (`Coverage ratchet passed - advancing to Human Review`), and stop; do not let the board re-enter AI Coverage on the resulting CI run, because the phase has already advanced past it.
   6. **On failure**, check the round cap first, then judge the round-over-round trend:
      - **Round cap**: if `MAX_COVERAGE_ITERATIONS` rounds have already run (counted from prior `... - returning to Development` coverage comments) without the branch catching up, whether or not this round's trend is itself closing: post a PR comment listing the still-failing languages and their gap, add the `Blocked` label, and stop. Do not write the coverage-baseline file.
      - Otherwise, compare each still-failing language's overall this round against its overall in the most recent prior coverage comment that mentions that language by name (not necessarily the immediately preceding round, since a language that passed in a round leaves no comment mentioning it for that round, so a later failure must be compared against its last-mentioned figure, not a stale or absent one). Treat a language as trending, with nothing yet to compare, only when no prior comment mentions it at all, regardless of which round this is, or when this is the whole PR's first coverage round.
      - **Gap closing** (every still-failing language's overall either improved versus its own previous coverage round, or is trending per the carve-out above): post a status comment in the form `<lang> <branch-pct>% < main <baseline-pct>% - returning to Development` (one line per failing language), move the board back to **Development**, and stop. Do not write the coverage-baseline file.
      - **Flat or worsening, and judged unlikely to close**: post a PR comment giving the per-language numbers, the round-over-round trend, and the specific reasoning for why coverage cannot realistically be raised further here, add the `Blocked` label, and stop. Do not write the coverage-baseline file. Unlike Phase B/C's self-detected non-convergence exit, this one blocks: a coverage round's pass/fail IS the ratchet's own verdict, so giving up here means proposing to waive the gate itself, not merely reporting that no new findings turned up; a human must see and agree with the reasoning before the gate is treated as satisfied.
      - **Flat or worsening, but more rounds are still judged worth trying**: post the status comment as in the gap-closing case above, move the board back to **Development**, and stop. Do not write the coverage-baseline file.

### Measuring Coverage and the Baseline File

`COVERAGE.md` is generated, never hand-edited, and is the sole persisted record of coverage. Its absence is a signal, not a free pass: anyone changing a repo without a `COVERAGE.md` must create it (bootstrap) and thereafter keep it updated. The comparison is per language, never blended into one figure. A language with no code or tests present in the repo is skipped, and Shell is excluded entirely: never measure it, always record it as `excluded`, and never include it in the comparison.

- **.NET**: components are assemblies. Collect each unit test project's `.cobertura.xml`, generate the per-assembly reports for the component rows, then generate the combined report and read its `summary.linecoverage` field for the gated Overall (.NET) figure. Skip .NET if the repo has no `*.Tests` project.
- **Node**: Vitest with the `@vitest/coverage-v8` provider and the `json-summary` reporter. Run `npx vitest run --coverage`, then read `jq '.total.lines.pct' coverage/coverage-summary.json`. Components are packages (one row per `package.json` with a configured test runner in a monorepo layout). Skip Node if the repo has no `package.json` with a configured test runner. Adding these packages to a repo for the first time still needs the normal human approval for third-party packages.
- **Python**: `coverage.py` run via `pytest`: `coverage run -m pytest`, then `coverage report --format=total` (prints only the overall percentage). Components are packages. Skip Python if the repo has no Python test suite.
- **Whole-repo test-infrastructure exclusion**: when every production assembly/package for a language in the repo carries a blanket coverage-instrumentation exclusion (the repo exists solely to provide test-support libraries), record that language as `excluded` with a one-line rationale and never measure or compare it. If only some assemblies/packages carry the exclusion, measure normally.

File format: a `# Coverage` heading and the line `Generated by the AI Coverage phase. Do not edit by hand.`, then a section per orchestrated language (.NET, Node, Python, Shell), even when skipped. A measured language lists every component in a table (component name, `Line Coverage`) plus a bold **Overall (\<Language\>)** row, which is the figure the gate compares; a language with one component still gets an explicit Overall row. Use `n/a (no code)` for a language with no code or tests (no table), and `excluded` for Shell or a whole-repo test-infrastructure exclusion (with a one-line rationale in the latter case). End with a `---` line and the line `Captured at commit <sha> on <ISO-8601 date>.`, where `<sha>` is the commit the numbers were measured against.

Bootstrap: `COVERAGE.md` reaches `main` for the first time via whichever branch's Pre-Work Baseline Check first finds it missing, as that branch's own first commit. Because `origin/main` still lacks the file, the comparison finds nothing to compare against on that same branch and must not block; overwrite `COVERAGE.md` again with the branch's live measurements (its second commit on that branch, which is expected), treat the gate as passed, and proceed as in the success case.

## Phase E: Mark Ready

Only once all four phases have completed without a `Blocked` outcome (each phase passed outright, or exited via its own non-blocking convergence path noted in a PR comment, or there were no reviewable changes):

1. Safety net (belt-and-suspenders on top of the Code Reviewer role's own Compliance sub-agent check, which already runs earlier in development, before this loop starts): confirm a `.deleteme.now` placeholder file is not present in `git diff origin/main...HEAD --name-only`; if it is still present, have Code Writer remove it and send it through the fix route without Changelog (correction), with Committer giving it its own commit, because a template-skip item has no changelog entry to correct, then continue.
2. Update the workflow board to **Human Review**, if configured, unless Phase D's success path already moved it there.
3. Mark the PR ready, but do not enable auto-merge yet:

   ```bash
   gh pr ready <number> --repo <owner/repo>
   ```

   Then post a status comment in the form `### AI Review Loop: reviewed <full head SHA>`, reading the SHA with `gh pr view <number> --repo <owner/repo> --json headRefOid --jq '.headRefOid'`, even when the PR was already ready and `gh pr ready` changed nothing, because this comment is the record of which head the loop last reviewed, and neither the PR's draft state nor its `ready_for_review` events move forward when the loop re-runs on a PR that is already ready.

   The PR has an unreviewed commit when its head SHA differs from the SHA in the latest accepted `### AI Review Loop: reviewed` comment, or when there is no such comment, because unreviewed change must not merge. Accept such a comment only when its author login is the bot login the orchestrator passes in, or a trusted commenter (a login in the "Trusted commenters" list the orchestrator passes in, or only the repository owner's login if no list is provided), because anyone else could post one naming a head the loop never reviewed. A rebase therefore leaves an unreviewed commit and re-runs the loop, which is acceptable because re-reviewing is safe while wrongly skipping review is not, and the check needs no local git state.

   Phase E is the only step that takes a PR out of draft, because every other role leaves it as draft until the loop has reviewed every commit. Enable auto-merge only later, in step 4, once every required check has a result produced after the PR was marked ready, because GitHub counts a check skipped on a draft as passed, so enabling auto-merge straight after marking ready can merge before lint, secret scanning and dependency review have run.

   Then, in an interactive session, hand CI to CI Monitor, stating the run mode and that the required checks skipped while the PR was a draft are now running for the first time, without stating that all required checks passed, because those checks have never run and nothing else would watch them. An unattended run needs no hand-off: stop here, because `oneshot` re-invokes the agent when the checks change, and that invocation runs step 4.
4. Enable auto-merge once every required check on the PR's current head has a result completed at or after the time the PR was last marked ready (a post-ready result), and none of those results failed, because a result from before that moment is the draft result, which GitHub counts as passed even when the check only skipped because the PR was a draft. A post-ready skip is a real result and counts as passed, because some required checks skip on a ready PR by design and never produce anything else. Judge failure from the plain `gh pr checks <number> --repo <owner/repo> --required` (its exit code and state column, never `--json`, because with `--json` gh exits 0 whatever the checks' state). Read when the PR was last marked ready from the first command below, which prints its last `ready_for_review` timeline event. If it prints nothing, the ready time is not known yet: treat every required check as having no post-ready result and look again on the next tick or invocation, because PR Submitter always opens the PR as a draft, so an empty read only means the event has not shown up yet. Read when each required check completed from the second:

   ```bash
   gh api repos/<owner>/<repo>/issues/<number>/timeline --paginate --jq '.[] | select(.event == "ready_for_review") | .created_at' | tail -n 1
   gh pr checks <number> --repo <owner/repo> --required --json name,completedAt --jq '.[] | "\(.completedAt)\t\(.name)"'
   ```

   A required check has a post-ready result when any of its rows completed at or after the ready time, because the same check can have one row from the run before the PR was marked ready and another from the run after it. Compare the two times as text, because both are UTC ISO 8601 times ending in `Z`. A check that has not completed yet has no post-ready result. Then:

   ```bash
   gh pr merge --auto --merge <number> --repo <owner/repo>
   ```

   - In an interactive session, do this when CI Monitor returns control after confirming all required checks pass with every one of them having a post-ready result, because that confirmation is the first moment the post-ready checks are known to have run and passed.
   - In an unattended run, do this on a later invocation when the PR is open and not a draft, `gh pr view <number> --repo <owner/repo> --json autoMergeRequest --jq '.autoMergeRequest'` prints `null`, the PR has no unreviewed commit, all required checks passed, and every required check has a post-ready result as above. While a required check has no post-ready result, stop and leave the PR as it is, because the post-ready run has not produced it yet.
   - If the PR has an unreviewed commit, for example from a Rebase Agent or human push, first turn auto-merge off (`gh pr merge <number> --repo <owner/repo> --disable-auto`, only when the `autoMergeRequest` read prints something other than `null`) and convert the PR to draft (`gh pr ready <number> --repo <owner/repo> --undo`), then run this loop for it instead of enabling auto-merge, because unreviewed change must not merge, and a draft PR is what lets the loop's own Phase E mark it ready again and start the post-ready checks.

   The PR is already ready at this point, which matters because GitHub rejects enabling auto-merge on a draft PR. If enabling auto-merge fails (auto-merge not supported), leave the PR ready for a human to merge.

## Environment/Infrastructure Block Marker (MANDATORY, PRs only)

When a `Blocked`-ing failure encountered during this loop is diagnosed as an environment or infrastructure problem (a bug in the container image, a missing tool, a transient infra issue) rather than a bug in the PR's own code, add a machine-readable marker alongside the diagnosis so `oneshot` can auto-clear `Blocked` once the fix has actually shipped, instead of the PR sitting blocked until a human happens to notice:

1. Post the full human-readable diagnosis as normal: root cause, evidence, and (if known) the fix needed.
2. Append a single trailer line to that same comment:

   ```text
   <!-- orchestrator:env-block image-sha=${IMAGE_SHA_DEVELOPMENT_AGENT} -->
   ```

   Read `IMAGE_SHA_DEVELOPMENT_AGENT` from your own container environment (the same value printed at session start as part of "Image layer provenance"); this records which image build was current when you made the diagnosis.
3. Apply the `Blocked` label as normal: `gh pr edit <number> --repo <owner/repo> --add-label "Blocked"`.
4. Use this marker **only** for a genuine environment/infrastructure diagnosis. `oneshot` auto-clears `Blocked` the moment it observes a differently-built agent image, with no further human involvement; marking a real code question or design decision this way would resume work before a human actually answered it.

This marker only applies to PRs; there is no container session, and therefore no image to diagnose against, before a PR/branch exists.

## Updating a Workflow Board

Always use the repo's `cfwf` tool for workflow board reads and writes; never hand-compose `gh project`, `gh repo view --json projectsV2`, or `gh api graphql` commands for it. Every command names the item with `--repo <owner/repo> --pr <number>`:

```bash
# Move the PR to a status (matched by display name, case-insensitive)
cfwf workflow-status --set --repo <owner/repo> --pr <number> --status "AI Review"

# Read the current status
cfwf workflow-status --check --repo <owner/repo> --pr <number>
```

- `--set` adds the item to the board if it is not already there and sets the status, then prints confirmation; exit 0 means the write was accepted (do not re-read it to confirm; GitHub's state lags behind writes). A non-zero exit means the write failed.
- `--check` prints the current status and exits non-zero if the item is not on the board. The output starts with the status name: match the name exactly and ignore anything after it.

Always attempt `cfwf` rather than deciding in advance that no board is configured: only conclude there is no board if `cfwf` itself reports finding no "Workflow" project linked to the repo, in which case skip board updates silently for the rest of the session.
