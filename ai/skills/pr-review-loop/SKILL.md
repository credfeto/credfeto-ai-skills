---
name: credfeto-pr-review-loop
description: Run the simplify, code-review, security-review, and coverage-ratchet passes on a pull request after all code changes are pushed and CI passes, before enabling auto-merge, including the changelog-correction step folded into each fix, how a static analyzer's rule always wins over a review suggestion, how the coverage ratchet gates on whole-repo per-language coverage rather than just the diff, and how to mark an environment-caused block for later auto-clearing. Use after CI is green on a PR and before marking it ready or enabling auto-merge.
---

# PR AI Review Loop

After all code changes are pushed and all required CI checks pass, run these phases in order **before** enabling auto-merge on the PR. Phases B, C, and D are each capped at a configurable maximum number of rounds (`MAX_REVIEW_ITERATIONS`); pick a small fixed number (e.g. 5) if the repo does not define one. Phase A uses its own, separate budget (see below).

## Phase A: Simplify (up to `MAX_SIMPLIFY_ITERATIONS` rounds, with a separate `SIMPLIFY_THRASH_LIMIT`)

1. Update the workflow board to a "simplify" status, if one is configured (see [Updating a Workflow Board](#updating-a-workflow-board) below).
2. Run a simplify pass against the diff that applies reuse, simplification, efficiency, and altitude cleanups directly rather than just reporting them.
3. If the simplify pass changed any files: run a changelog-correction pass against the resulting diff; commit the code changes and, if the changelog entry changed, commit `CHANGELOG.md` separately; push; then repeat step 2 against the resulting diff.
4. Once the simplify pass makes no further changes, proceed to Phase B.
5. Simplify has its own iteration budget, kept deliberately separate from `MAX_REVIEW_ITERATIONS` (used by Phases B-D below), because it is expected to run more rounds and give up without blocking:
   - Track each round's diff size (lines changed by that round's simplify commit) against the previous round's.
   - Once `SIMPLIFY_THRASH_LIMIT` rounds have run, if the current round is thrashing (its diff is flat or larger than the previous round's, i.e. not shrinking): give up immediately, even though `MAX_SIMPLIFY_ITERATIONS` has not been reached.
   - Otherwise, keep re-running up to `MAX_SIMPLIFY_ITERATIONS` rounds total; once that hard cap is reached without converging to no changes, give up regardless of whether the diff was still shrinking.
   - Either way, giving up means: post a PR comment noting that simplify did not converge, then proceed to Phase B with the diff as it currently stands. **Do not add `Blocked` and do not stop**; unlike Phases B-D, non-convergence in Phase A never blocks the PR, because Phase B's code-review pass re-covers the same reuse/simplification/efficiency categories as a safety net.

## Phase B: Code Review (up to `MAX_REVIEW_ITERATIONS` rounds)

1. Update the workflow board to a "review" status, if configured.
2. Run a code-review pass that posts inline PR comments for its findings. This intentionally re-covers the reuse/simplification/efficiency categories Phase A already applied (Phase A fixes them silently; this step verifies nothing was missed) and separately checks correctness, which Phase A does not. Security and compliance are not covered here; they remain Phase C's job. Expect this step to usually find nothing in the categories Phase A already handled.
3. If inline PR comment findings were posted: fix each in its own commit; after each fix, run a changelog-correction pass and commit `CHANGELOG.md` separately if the entry changed; push; return to step 2.
4. After `MAX_REVIEW_ITERATIONS` rounds with unresolved findings: post a PR comment listing them, add the `Blocked` label, and **stop**:

   ```bash
   gh pr edit <number> --repo <owner/repo> --add-label Blocked
   ```

## Conflict Resolution: Simplify/Code Review vs. Static Analyzer

If a change proposed by the simplify pass (Phase A) or a finding raised by the code-review pass (Phase B) would conflict with a rule enforced by the project's build-time static analyzer stack, or by any org-owned code-analysis package, **the static analyzer's rule always wins**: do not apply the conflicting simplify/code-review suggestion, and keep the analyzer-compliant code as-is.

## Phase C: Security Review (up to `MAX_REVIEW_ITERATIONS` rounds)

1. Update the workflow board to a "security review" status, if configured.
2. Run a security-review pass against the diff.
3. If findings are reported (inline or in output): post them as a PR comment if not already inline; fix each in its own commit; after each fix, run a changelog-correction pass and commit `CHANGELOG.md` separately if the entry changed; push; return to step 2.
4. After `MAX_REVIEW_ITERATIONS` rounds with unresolved findings: post a PR comment, add the `Blocked` label, and **stop**.

## Phase D: AI Coverage (up to `MAX_REVIEW_ITERATIONS` rounds)

This phase gates on the whole repo's per-language coverage, not just the lines the PR's own diff touches; it exists to catch a deleted test or an untouched-code regression that a diff-only coverage check would miss.

1. Update the workflow board to an "AI Coverage" status, if configured.
2. Run the coverage ratchet decision procedure:
   1. If every file changed on the branch (relative to its merge-base with `main`) falls into a non-code category, dependency-manifest/version-pin bumps, CI workflow YAML beyond version pins, SQL, shell scripts, Dockerfiles, or documentation-only changes, skip straight to step 2.5 without measuring anything; nothing that changed could have moved any language's coverage.
   2. Fetch `origin/main` fresh and read its committed coverage-baseline file (e.g. `COVERAGE.md` at the repo root) without checking it out. If it does not exist yet, this is a first-time bootstrap: there is no baseline to compare against, so treat the gate as passed and continue to step 2.5.
   3. For each orchestrated language with a real baseline figure in that file (not "n/a" or "excluded"), measure that language's current overall line coverage on the branch's working tree.
   4. Compare branch vs. baseline **overall** coverage per language (never blended across languages, and never gated on a single project/component dipping while its language's overall holds or improves): any language whose branch overall is below its baseline overall fails the gate.
   5. **On success**: write/overwrite the coverage-baseline file with the numbers just measured (or the branch's current measurement, in the skip/bootstrap cases), commit and push it, move the board to **Human Review**, post a one-line status comment (`Coverage ratchet passed - advancing to Human Review`), and stop; do not let the board re-enter AI Coverage on the resulting CI run.
   6. **On failure**: post one status-comment line per failing language in the form `<lang> <branch-pct>% < main <baseline-pct>% - returning to Development`, move the board back to **Development**, leave the coverage-baseline file untouched, and stop; the next work cycle picks the resulting Development work back up.
3. **Round cap**: counting rounds from prior `... - returning to Development` coverage comments, after `MAX_REVIEW_ITERATIONS` rounds without the branch catching up: post a PR comment listing the still-failing languages and their gap, add the `Blocked` label, and **stop**.

## Phase E: Mark Ready

Only once all four phases pass (or there were no reviewable changes):

1. Update the workflow board to a "human review" status, if configured, unless Phase D's success path already moved it there.
2. Enable auto-merge:

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

If the repo's agent-facing instructions define a workflow board (a GitHub Projects v2 board with a Status field, typically supplied as project ID / status field ID / per-status option IDs), update it at each phase transition above by running these steps in sequence:

```bash
# Step 1: resolve the item node ID
ITEM_NODE_ID=$(gh api repos/<owner/repo>/pulls/<number> --jq '.node_id')

# Step 2: add item to project and capture the project item ID (idempotent: safe to call again for an item already in the project)
PROJECT_ITEM_ID=$(gh api graphql \
  -f query='mutation($p:ID!,$c:ID!){addProjectV2ItemById(input:{projectId:$p,contentId:$c}){item{id}}}' \
  -f p="${WF_PROJECT_ID}" -f c="${ITEM_NODE_ID}" \
  --jq '.data.addProjectV2ItemById.item.id')

# Step 3: set the Status field
gh api graphql \
  -f query='mutation($p:ID!,$i:ID!,$f:ID!,$v:String!){updateProjectV2ItemFieldValue(input:{projectId:$p,itemId:$i,fieldId:$f,value:{singleSelectOptionId:$v}}){projectV2Item{id}}}' \
  -f p="${WF_PROJECT_ID}" -f i="${PROJECT_ITEM_ID}" \
  -f f="${WF_STATUS_FIELD_ID}" -f v="<STATUS_OPTION_ID>" > /dev/null

# Step 4: verify the write actually persisted; retry up to 3 times with backoff if not
for attempt in 1 2 3; do
  ACTUAL=$(gh api graphql \
    -f query='query($i:ID!){node(id:$i){... on ProjectV2Item{fieldValues(first:50){nodes{... on ProjectV2ItemFieldSingleSelectValue{optionId field{... on ProjectV2SingleSelectField{id}}}}}}}}' \
    -f i="${PROJECT_ITEM_ID}" \
    --jq ".data.node.fieldValues.nodes[] | select(.field.id==\"${WF_STATUS_FIELD_ID}\") | .optionId")
  [ "$ACTUAL" = "<STATUS_OPTION_ID>" ] && break
  sleep "$attempt"
done
[ "$ACTUAL" = "<STATUS_OPTION_ID>" ] || echo "::warning::Workflow board write did not persist after 3 attempts"
```

Step 4 is **mandatory, not optional**: `updateProjectV2ItemFieldValue` can return success (no GraphQL error) on an item that was just added by `addProjectV2ItemById`, without the field write actually persisting; a known eventual-consistency race in the Projects v2 API on freshly-added items. Reporting success without this read-back verification is a real bug that has shipped in practice because nothing threw. Never skip the verification step to save a round-trip.

If no board configuration is present, skip all board updates silently; the comment/label flow above is sufficient on its own.
