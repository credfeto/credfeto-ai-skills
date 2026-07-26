---
name: credfeto-pr-review-loop
description: Run the simplify, code-review, and security-review passes on a pull request after all code changes are pushed and CI passes, before enabling auto-merge, including how a static analyzer's rule always wins over a review suggestion and how to mark an environment-caused block for later auto-clearing. Use after CI is green on a PR and before marking it ready or enabling auto-merge.
---

# PR AI Review Loop

After all code changes are pushed and all required CI checks pass, run these phases in order **before** enabling auto-merge on the PR. Each phase is capped at a configurable maximum number of rounds (`MAX_REVIEW_ITERATIONS`); pick a small fixed number (e.g. 5) if the repo does not define one.

## Phase A: Simplify

1. Update the workflow board to a "simplify" status, if one is configured (see [Updating a Workflow Board](#updating-a-workflow-board) below).
2. Run a simplify pass against the diff that applies reuse, simplification, efficiency, and altitude cleanups directly rather than just reporting them.
3. If the simplify pass changed any files: commit and push them, then repeat step 2 against the resulting diff.
4. Once the simplify pass makes no further changes, proceed to Phase B.
5. If `MAX_REVIEW_ITERATIONS` rounds pass and the simplify pass is still changing files (not converging): post a PR comment explaining that simplification is not converging, add the `Blocked` label, and **stop**.

## Phase B: Code Review

1. Update the workflow board to a "review" status, if configured.
2. Run a code-review pass that posts inline PR comments for its findings. This intentionally re-covers the reuse/simplification/efficiency categories Phase A already applied (Phase A fixes them silently; this step verifies nothing was missed) and separately checks correctness, which Phase A does not. Security and compliance are not covered here; they remain Phase C's job. Expect this step to usually find nothing in the categories Phase A already handled.
3. If inline PR comment findings were posted: fix each in its own commit, push, and return to step 2.
4. After `MAX_REVIEW_ITERATIONS` rounds with unresolved findings: post a PR comment listing them, add the `Blocked` label, and **stop**:

   ```bash
   gh pr edit <number> --repo <owner/repo> --add-label Blocked
   ```

## Conflict Resolution: Simplify/Code Review vs. Static Analyzer

If a change proposed by the simplify pass (Phase A) or a finding raised by the code-review pass (Phase B) would conflict with a rule enforced by the project's build-time static analyzer stack, or by any org-owned code-analysis package, **the static analyzer's rule always wins**: do not apply the conflicting simplify/code-review suggestion, and keep the analyzer-compliant code as-is.

## Phase C: Security Review

1. Update the workflow board to a "security review" status, if configured.
2. Run a security-review pass against the diff.
3. If findings are reported (inline or in output): post them as a PR comment if not already inline, fix each in its own commit, push, and return to step 2.
4. After `MAX_REVIEW_ITERATIONS` rounds with unresolved findings: post a PR comment, add the `Blocked` label, and **stop**.

## Phase D: Mark Ready

Only once all three phases pass (or there were no reviewable changes):

1. Update the workflow board to a "human review" status, if configured.
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

If the repo's agent-facing instructions define a workflow board (a GitHub Projects v2 board with a Status field, typically supplied as project ID / status field ID / per-status option IDs), update it by running these three steps in sequence at each phase transition above:

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
```

If no board configuration is present, skip all board updates silently; the comment/label flow above is sufficient on its own.
