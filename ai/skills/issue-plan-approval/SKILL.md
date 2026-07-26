---
name: credfeto-issue-plan-approval
description: Post an implementation plan on a GitHub issue and wait for explicit human approval before starting work on it, when picking up an issue that has no PR yet. Use when selecting or resuming a GitHub issue with no existing pull request, before writing any code against it.
---

# Issue Plan-First Approval Gate

When picking up a GitHub **issue** that has no existing PR, do not start implementing directly. Run the pre-work baseline check for the repo first (verify prerequisites, run the pre-commit baseline, run any repo build-health check), then follow this gate.

## 1. Check for an Existing Plan

```bash
gh issue view <number> --repo <owner/repo> --json comments \
  --jq '[.comments[].body] | any(test("## Implementation Plan"; "i"))'
```

- `false` → no plan posted yet; go to [Post the Plan](#2-post-the-plan).
- `true` → a plan already exists; go to [Check for Approval](#3-check-for-approval).

## 2. Post the Plan

Produce a concrete implementation plan (using a planning mode if the tool provides one), then post it as an issue comment in **exactly** this format:

```text
## Implementation Plan

### Files to change
- `path/to/file`: reason

### Approach
<one-paragraph description>

### Test strategy
<what will be tested and how>

### Assumptions
<list or "None">

### Open questions
<list or "None, ready to proceed pending approval">
```

Then mark the issue Blocked and **stop**:

```bash
gh issue edit <number> --repo <owner/repo> --add-label Blocked
```

## 3. Check for Approval

How approval is signalled depends on whether the repo uses a GitHub Projects workflow board for this (some repos configure one; check the repo's own agent-facing instructions for board field IDs before assuming one exists):

- **Board configured**: check whether a human has set the board status to **Approved**. If yes, proceed to implementation. If not yet, revise or re-post the plan, keep the issue Blocked, and stop.
- **No board**: check for a human approval comment posted **after** the plan comment (keywords: `approved` / `go ahead` / `looks good` / `lgtm`, case-insensitive, whole word). If found, proceed to implementation. If not found, revise or re-post the plan, keep the issue Blocked, and stop.

Approval always requires an explicit human action; never remove `Blocked` or treat the plan as approved automatically, no matter how much time has passed or how confident the plan seems.

If a human answers or approves in a live chat session rather than posting a GitHub comment directly, post the comment yourself, quoting the live instruction, before treating it as approval and before removing `Blocked`. The record must survive even if the chat session is lost.

## Updating a Workflow Board

If the repo's agent-facing instructions define a workflow board (a GitHub Projects v2 board with a Status field, typically supplied as project ID / status field ID / per-status option IDs), update it by running these three steps in sequence whenever this gate changes the issue's status (e.g. to **Planning** after posting a plan):

```bash
# Step 1: resolve the item node ID
ITEM_NODE_ID=$(gh api repos/<owner/repo>/issues/<number> --jq '.node_id')

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
