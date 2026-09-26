---
name: credfeto-pr-review-loop
description: Run the simplify, code-review, security-review, and coverage-ratchet passes on a pull request after all code changes are pushed and CI passes, before enabling auto-merge, including the changelog-correction step and Pattern Sweep folded into each fix, how each review phase can exit without blocking once it stops finding anything new, how a static analyzer's rule always wins over a review suggestion, how the coverage ratchet gates on whole-repo per-language coverage rather than just the diff and blocks when it judges the gap unlikely to close, and how to mark an environment-caused block for later auto-clearing. Use after CI is green on a PR and before marking it ready or enabling auto-merge.
---

# PR AI Review Loop

After all code changes are pushed and all required CI checks pass, run these phases in order **before** enabling auto-merge on the PR. Phases B, C, and D each have their own configurable maximum number of rounds (`MAX_CODE_REVIEW_ITERATIONS`, `MAX_SECURITY_REVIEW_ITERATIONS`, `MAX_COVERAGE_ITERATIONS` respectively), defined by the repo. Phase A uses its own, separate budget (see below).

## Phase A: Simplify (up to `MAX_SIMPLIFY_ITERATIONS` rounds, with a separate `SIMPLIFY_THRASH_LIMIT`)

1. Update the workflow board to **AI Simplify**, if one is configured (see [Updating a Workflow Board](#updating-a-workflow-board) below).
2. Run a simplify pass against the diff that applies reuse, simplification, efficiency, and altitude cleanups directly rather than just reporting them. Also apply IDE MCP code analysis to the modified files.
3. If the simplify pass changed any files: run a changelog-correction pass against the resulting diff; commit the code changes and, if the changelog entry changed, commit `CHANGELOG.md` separately; push; then repeat step 2 against the resulting diff.
4. Once the simplify pass makes no further changes: run a Pattern Sweep for each construct in the net Phase A diff (the commits since step 1), not per round, since rounds may revert each other and each sweep would widen the next round's diff. A change with no repeatable construct (a local rename or restructuring) has nothing to sweep. If the sweep changed files: commit, run changelog-correction and commit `CHANGELOG.md` separately if the entry changed, push, then proceed to Phase B instead of returning to step 2 (Phase B re-covers the swept code).
5. Simplify has its own iteration budget, kept deliberately separate from Phases B-D's budgets, because it is expected to run more rounds and give up without blocking:
   - Track each round's diff size (lines changed by that round's simplify commit) against the previous round's.
   - Once `SIMPLIFY_THRASH_LIMIT` rounds have run, if the current round is thrashing (its diff is flat or larger than the previous round's, i.e. not shrinking): give up immediately, even though `MAX_SIMPLIFY_ITERATIONS` has not been reached.
   - Otherwise, keep re-running up to `MAX_SIMPLIFY_ITERATIONS` rounds total; once that hard cap is reached without converging to no changes, give up regardless of whether the diff was still shrinking.
   - Either way, giving up means: post a PR comment noting that simplify did not converge, run step 4 in full (sweep, commit, changelog correction, push) on the diff as it currently stands, then proceed to Phase B. **Do not add `Blocked` and do not stop**, with one exception: a Pattern Sweep that would touch more than 25 files is never applied silently — it posts the site list on the PR, adds `Blocked`, and waits for a human decision on whether it belongs in this PR or a follow-up issue; that gate applies in every phase and is the one reason Phase A may add `Blocked`, after which the sweep is committed or discarded on the human's decision and Phase A continues. Barring that gate, non-convergence in Phase A never otherwise blocks the PR, because Phase B's code-review pass re-covers the same reuse/simplification/efficiency categories as a safety net.

## Phase B: Code Review (up to `MAX_CODE_REVIEW_ITERATIONS` rounds)

1. Update the workflow board to **AI Review**, if configured.
2. Run a code-review pass that posts inline PR comments for its findings. This intentionally re-covers the reuse/simplification/efficiency categories Phase A already applied (Phase A fixes them silently; this step verifies nothing was missed) and separately checks correctness, which Phase A does not. Security and compliance are not covered here; they remain Phase C's job. Also apply IDE MCP code analysis to the modified files. Expect this step to usually find nothing in the categories Phase A already handled.
3. If no findings were posted: proceed to Phase C.
4. Otherwise, judge convergence from the PR's history of prior code-review comments: are this round's findings substantively new/distinct, or substantially a repeat of findings already reported (and left unresolved, or fixed and now recurring) in an earlier round? `MIN_REVIEW_CONVERGENCE_ROUNDS` must be set below `MAX_CODE_REVIEW_ITERATIONS`, otherwise the round-cap branch below always fires first and the non-blocking exit can never trigger.
   - If `MAX_CODE_REVIEW_ITERATIONS` rounds have already run and findings remain, whether or not this round's findings are themselves new: post a PR comment listing the unresolved findings, add the `Blocked` label, and **stop**:

     ```bash
     gh pr edit <number> --repo <owner/repo> --add-label Blocked
     ```

   - Otherwise, if substantially repeating a prior round (not converging) AND at least `MIN_REVIEW_CONVERGENCE_ROUNDS` rounds have now run: post a PR comment summarising the unresolved findings and stating that code review is not converging, advance the board to **AI Security Review** if configured, post a one-line status comment, then proceed to Phase C. **Do not add `Blocked`**: this means no new correctness issues are surfacing, not that a known one is safe to ignore; the posted comment carries the unresolved findings forward to human review.
   - Otherwise (substantively new findings, or a repeat but fewer than `MIN_REVIEW_CONVERGENCE_ROUNDS` rounds have run so far, and the round cap has not been reached): fix each finding, grouped by construct, in its own commit, with a Pattern Sweep for that construct (a finding that only re-reports a construct a sweep already touched is not substantively new for the convergence judgment above; a new bug in those files is); after each fix and its sweep, run a changelog-correction pass and commit `CHANGELOG.md` separately if the entry changed; push; return to step 2.

## Conflict Resolution: Simplify/Code Review vs. Static Analyzer

If a change proposed by the simplify pass (Phase A) or a finding raised by the code-review pass (Phase B) would conflict with a rule enforced by the project's build-time static analyzer stack, or by any org-owned code-analysis package, **the static analyzer's rule always wins**: do not apply the conflicting simplify/code-review suggestion, and keep the analyzer-compliant code as-is.

## Phase C: Security Review (up to `MAX_SECURITY_REVIEW_ITERATIONS` rounds)

This phase mirrors Phase B exactly, substituting security-review for code-review; keep both in sync when editing either.

1. Update the workflow board to **AI Security Review**, if configured.
2. Run a security-review pass against the diff. Also apply IDE MCP code analysis to the modified files.
3. If no findings are reported: proceed to Phase D.
4. Otherwise, judge convergence from the PR's history of prior security-review comments, the same way as Phase B step 4 above (`MIN_REVIEW_CONVERGENCE_ROUNDS` must again be set below `MAX_SECURITY_REVIEW_ITERATIONS`):
   - If `MAX_SECURITY_REVIEW_ITERATIONS` rounds have already run and findings remain: post a PR comment listing the unresolved findings, add the `Blocked` label, and **stop**.
   - Otherwise, if substantially repeating a prior round AND at least `MIN_REVIEW_CONVERGENCE_ROUNDS` rounds have now run: post a PR comment summarising the unresolved findings and stating that security review is not converging, advance the board to **AI Coverage** if configured, post a one-line status comment, then proceed to Phase D. **Do not add `Blocked`**, for the same reason as Phase B's equivalent exit.
   - Otherwise: post findings as a PR comment if not already inline, fix each finding grouped by construct in its own commit with a Pattern Sweep, run changelog-correction and commit `CHANGELOG.md` separately if the entry changed after each fix and sweep, push, return to step 2.

## Phase D: AI Coverage (up to `MAX_COVERAGE_ITERATIONS` rounds)

This phase gates on the whole repo's per-language coverage, not just the lines the PR's own diff touches; it exists to catch a deleted test or an untouched-code regression that a diff-only coverage check would miss.

1. Update the workflow board to **AI Coverage**, if configured.
2. Run the coverage ratchet decision procedure:
   1. If every file changed on the branch (relative to its merge-base with `main`) falls into a non-code category (dependency-manifest/version-pin bumps, CI workflow YAML beyond version pins, SQL, shell scripts, Dockerfiles, or documentation-only changes), skip straight to step 5 without measuring anything; nothing that changed could have moved any language's coverage.
   2. Fetch `origin/main` fresh and read its committed coverage-baseline file (e.g. `COVERAGE.md` at the repo root) without checking it out. If it does not exist yet, this is a first-time bootstrap: there is no baseline to compare against, so treat the gate as passed and continue to step 5.
   3. For each orchestrated language with a real baseline figure in that file (not "n/a" or "excluded"), measure that language's current overall line coverage on the branch's working tree.
   4. Compare branch vs. baseline **overall** coverage per language (never blended across languages, and never gated on a single project/component dipping while its language's overall holds or improves): any language whose branch overall is below its baseline overall fails the gate.
   5. **On success**: write/overwrite the coverage-baseline file with the numbers just measured (or the branch's current measurement, in the skip/bootstrap cases), commit and push it, move the board to **Human Review**, post a one-line status comment (`Coverage ratchet passed - advancing to Human Review`), and stop; do not let the board re-enter AI Coverage on the resulting CI run.
   6. **On failure**, check the round cap first, then judge the round-over-round trend:
      - **Round cap**: if `MAX_COVERAGE_ITERATIONS` rounds have already run (counted from prior `... - returning to Development` coverage comments) without the branch catching up, whether or not this round's trend is itself closing: post a PR comment listing the still-failing languages and their gap, add the `Blocked` label, and stop. Do not write the coverage-baseline file.
      - Otherwise, compare each still-failing language's overall this round against its overall in the most recent prior coverage comment that mentions that language by name (not necessarily the immediately preceding round, since a language that passed in a round leaves no comment mentioning it that round). Treat a language as trending, with nothing yet to compare, only when no prior comment mentions it at all, or this is the whole PR's first coverage round.
      - **Gap closing** (every still-failing language's overall either improved versus its own previous round, or is trending per the carve-out above): post a status comment in the form `<lang> <branch-pct>% < main <baseline-pct>% - returning to Development` (one line per failing language), move the board back to **Development**, and stop. Do not write the coverage-baseline file.
      - **Flat or worsening, and judged unlikely to close**: post a PR comment giving the per-language numbers, the round-over-round trend, and the specific reasoning for why coverage cannot realistically be raised further here, add the `Blocked` label, and stop. Do not write the coverage-baseline file. Unlike Phase B/C's self-detected non-convergence exit, this one blocks: a coverage round's pass/fail IS the ratchet's own verdict, so giving up here means proposing to waive the gate itself, not merely reporting that no new findings turned up; a human must see and agree with the reasoning before the gate is treated as satisfied.
      - **Flat or worsening, but more rounds are still judged worth trying**: post the status comment as in the gap-closing case above, move the board back to **Development**, and stop. Do not write the coverage-baseline file.

## Phase E: Mark Ready

Only once all four phases have completed without a `Blocked` outcome (each phase passed outright, or exited via its own non-blocking convergence path noted in a PR comment, or there were no reviewable changes):

1. Safety net (belt-and-suspenders on top of the Compliance sub-agent's own check during Phase B): confirm a `.deleteme.now` placeholder file is not present in `git diff origin/main...HEAD --name-only`; if it is still present, remove it in its own commit, re-run the build/test verification role, then continue.
2. Update the workflow board to **Human Review**, if configured, unless Phase D's success path already moved it there.
3. Enable auto-merge:

   ```bash
   gh pr merge --auto --merge <number> --repo <owner/repo>
   ```

   If that fails because auto-merge is not supported on the repo, fall back to:

   ```bash
   gh pr ready <number> --repo <owner/repo>
   ```

## Environment/Infrastructure Block Marker (MANDATORY, PRs only)

When a `Blocked`-ing failure encountered during this loop is diagnosed as an environment or infrastructure problem (a bug in the execution image, a missing tool, a transient infra issue) rather than a bug in the PR's own code, append a machine-readable marker so an automated gate can auto-clear `Blocked` once the fix has actually shipped, instead of the PR sitting blocked until a human happens to notice:

1. Post the full human-readable diagnosis as normal: root cause, evidence, and (if known) the fix needed.
2. Append a single trailer line to that same comment, using whatever image/build identifier your execution environment exposes:

   ```text
   <!-- orchestrator:env-block image-sha=${IMAGE_SHA_DEVELOPMENT_AGENT} -->
   ```

3. Apply the `Blocked` label as normal: `gh pr edit <number> --repo <owner/repo> --add-label "Blocked"`.
4. Use this marker **only** for a genuine environment/infrastructure diagnosis. An automated gate using this marker will auto-clear `Blocked` the moment it observes a differently-built execution image, with no further human involvement; marking a real code question or design decision this way would resume work before a human actually answered it.

This marker only applies to PRs; there is no environment session, and therefore no image to diagnose against, before a PR/branch exists.

## Updating a Workflow Board

Always use the repo's `cfwf` tool for workflow board reads and writes; never hand-compose `gh project`, `gh repo view --json projectsV2`, or `gh api graphql` commands for it. Every command names the item with `--repo <owner/repo> --pr <number>`:

```bash
# Move the PR to a status (matched by display name, case-insensitive)
cfwf workflow-status --set --repo <owner/repo> --pr <number> --status "AI Review"

# Read the current status
cfwf workflow-status --check --repo <owner/repo> --pr <number>
```

- `--set` adds the item to the board if it is not already there and sets the status, then prints confirmation; exit 0 means the write was accepted (do not re-read it to confirm; GitHub's state lags behind writes). A non-zero exit means the write failed.
- `--check` prints the current status and exits non-zero if the item is not on the board. The output starts with the status name and may be followed by a parenthetical; match the name exactly and ignore anything after it.

Always attempt `cfwf` rather than deciding in advance that no board is configured: only conclude there is no board if `cfwf` itself reports finding no "Workflow" project linked to the repo, in which case skip board updates silently for the rest of the session.
