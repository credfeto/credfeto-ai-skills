---
name: credfeto-issue-plan-approval
description: Post an implementation plan on a GitHub issue and wait for explicit human approval before starting work on it, when picking up an issue that has no PR yet, including how to keep waiting for approval within an interactive session rather than ending the turn. Use when selecting or resuming a GitHub issue with no existing pull request, before writing any code against it.
---

# Issue Plan-First Approval Gate

When picking up a GitHub **issue** that has no existing PR, do not start implementing directly. Run the repo's Pre-Work Baseline Check first, then follow this gate.

## 1. Check for an Existing Plan

```bash
gh issue view <number> --repo <owner/repo> --json comments \
  --jq '[.comments[].body] | any(test("^## Implementation Plan"; "i"))'
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
<list, using a lower-case alpha sequence (a., b., c., ...), or "None">

### Open questions
<list, using a Q-prefixed numbered sequence (Q1., Q2., Q3., ...), or "None, ready to proceed pending approval">
```

**Open questions vs. embedded conditional decisions:** any conditional or deferred decision point in the Approach or Files-to-change text — a decision the plan does not itself resolve (e.g. "needs policy sign-off", "pending a decision on X", an either/or left open) — must be lifted out into its own `Qn.` entry under Open questions, not left as prose in Approach/Files-to-change. Prose framing hides it from the Blocked/approval gate below, which only inspects Open questions; a `Qn.` entry is what actually forces it through that gate. A matching check applies again before the issue is later closed: do not close it while a decision flagged this way, or in a later comment, is still unresolved.

Then mark the issue Blocked, update the workflow board to a "Planning" status if one is configured (see [Updating a Workflow Board](#updating-a-workflow-board) below), and **stop**:

```bash
gh issue edit <number> --repo <owner/repo> --add-label Blocked
```

Use only the `Blocked` label for this purpose; never a substitute such as `do not merge` or `needs review`; routing logic elsewhere only recognises `Blocked` when deciding whether to skip an item.

Revise a plan only by posting a new `## Implementation Plan` comment, never by editing an existing one in place, so approval is always judged against the latest plan comment.

## 3. Check for Approval

How approval is signalled depends on whether the repo uses a GitHub Projects workflow board for this (some repos configure one; check the repo's own agent-facing instructions before assuming one exists):

- **Board configured**: check whether a human with project write access (an `OWNER`, `MEMBER` or `COLLABORATOR`; the board only lets people with that access move a card) has set the board status to **Approved** (see [Updating a Workflow Board](#updating-a-workflow-board) below). If yes, check for an existing branch first (see below), then proceed to implementation. If not yet, revise or re-post the plan (as a new comment, never in place), keep the issue Blocked, and stop.
- **No board**: check for an approval comment posted **after** the plan comment, from a commenter whose `authorAssociation` is `OWNER`, `MEMBER` or `COLLABORATOR` (keywords: `approved` / `lgtm`, case-insensitive, whole word: an unconditional approval, not a question, a negation, or a qualified approval such as "approved, but ..."). If found, check for an existing branch first (see below), then proceed to implementation. If not found, revise or re-post the plan (as a new comment, never in place), keep the issue Blocked, and stop.

Either way, before skipping to implementation once approved, check whether a branch for this issue already exists (e.g. from an earlier session) and resume it rather than starting a fresh one.

Approval always requires an explicit human action; never remove `Blocked` or treat the plan as approved automatically, no matter how much time has passed or how confident the plan seems.

If a human answers or approves in a live chat session rather than posting a GitHub comment directly, post the comment yourself, quoting the live instruction, before treating it as approval and before removing `Blocked`. The record must survive even if the chat session is lost. The one documented exception, which waives only the requirement that a human clears `Blocked` (never the mirror-comment requirement), is live-chat approval handled within an interactive session; see [Waiting for Approval in an Interactive Session](#waiting-for-approval-in-an-interactive-session) below.

**Check GitHub's live state, not just chat.** A human's approval action may land directly on the issue (a comment, a label change, moving the board card) without also being repeated in chat: they already have to open the issue to read the posted plan, so relaying it a second time in chat is not something to wait on. Before treating the issue as approved, still blocked, or unchanged, re-check its live state (labels, comments, and the board's status via a workflow-status check) rather than relying on stale memory or assuming silence in chat means nothing has happened on GitHub. This cuts both ways: a literal chat-only approval (a human typing `approved`/`lgtm` directly into the chat session) is still valid on its own, but must be mirrored as a GitHub comment so the record survives even if the chat session is lost; and an unexplained GitHub-side state change must not be treated as approval without confirming a human actually made it, since an automated board rule or a stray process flipping a field is not a human decision.

## Waiting for Approval in an Interactive Session

Applies only to an interactive session: one where a human has actually typed a message in it (an injected prompt or task notification does not count; if unsure, assume the session is unattended). An unattended run stops once the plan is posted and Blocked is added, and must not poll.

- Once the plan is posted and Blocked added (or, on resume, once an existing plan is found not yet approved), "stop" means stop working on the issue, not stop watching it: take the latest plan comment's `createdAt` as the approval baseline and start a recurring, dynamically-paced check instead of ending the turn (e.g. via a scheduling/loop mechanism the tool provides), re-running the approval check above on each tick.
- Each tick, decide from the labels, the latest plan comment, and any qualifying approval comment/board status posted after it, without stopping early so a half-finished approval is not missed:
  - **Approved**: `Blocked` is absent, a plan exists, and either the board reads Approved (board configured) or a qualifying approval comment exists (no board), and the plan is still the same one taken as the baseline. Stop waiting and proceed to implementation (checking for an existing branch first).
  - **Half-finished**: the approval signal is present but `Blocked` has not actually been cleared yet. Keep waiting and tell the human as soon as this is seen.
  - **Otherwise**: not yet; wait silently.
  - If the plan comment taken as the baseline has since been superseded by a newer one, treat the plan as changed: earlier approvals no longer count. If you revised the plan yourself, restart from posting the plan (re-add `Blocked`, new baseline); if someone else posted it, tell the human and wait for their direction.
- Pace the wait with long idle intervals (e.g. around 20 minutes) while nothing has changed, rather than polling tightly; there is no overall cap on how long the wait may run. If no scheduling mechanism is available, do not poll at all: tell the human the issue is waiting and that saying `approved` in chat will continue the work.
- **Live-chat approval ends the wait immediately.** If the human's chat message opens with the literal word `approved` or `lgtm` (case-insensitive) and is otherwise an unconditional approval (not a question, a negation, or a qualified approval), act at once rather than waiting for the next tick:
  1. Re-check that the message refers to this issue, the plan is still the baseline, `Blocked` is only the plan-approval block (no comment posted after the plan asks a question, reports a failed baseline check or a timeout, or carries an environment-block marker), and the plan has no unresolved open questions; if any check fails, ask instead of acting.
  2. Post a mirror comment on the issue quoting the live instruction.
  3. Remove the `Blocked` label.
  4. If the repo has a workflow board, set its status to Approved.
  5. Stop waiting and proceed to implementation as above.

## Scope: Issues Only, Never Re-Checked at PR Time

This gate governs only picking up an issue that has **no existing PR**. Once a PR exists for the issue, this gate no longer applies: a PR is never opened for an issue until this gate has already been passed by a human, so the PR's own existence *is* the authorisation.

A session working the PR phase must never re-derive or re-check approval from the PR's own workflow board card; that card is purely a phase marker for the separate PR review workflow, not a second approval gate. If a PR's own board card still reads an early-stage status (e.g. "Not Started", "Planning", or "Approved": for example because the session that opened the draft PR died before advancing its card, or a freshly-seeded board has not caught up yet), treat that as "Development" and continue with the PR review workflow: never block pending approval, and never treat the stale card as evidence the linked issue was never approved. The issue and PR cards are kept in step automatically, forward-only, by the orchestrating system itself; this is not something a session needs to reconcile by hand.

## Updating a Workflow Board

Always use the repo's `cfwf` tool for workflow board reads and writes; never hand-compose `gh project`, `gh repo view --json projectsV2`, or `gh api graphql` commands for it. Every command names the item with `--repo <owner/repo> --issue <number>`:

```bash
# Move the issue to a status (matched by display name, case-insensitive)
cfwf workflow-status --set --repo <owner/repo> --issue <number> --status "Planning"

# Read the current status
cfwf workflow-status --check --repo <owner/repo> --issue <number>
```

- `--set` adds the item to the board if it is not already there and sets the status, then prints confirmation; exit 0 means the write was accepted (do not re-read it to confirm; GitHub's state lags behind writes). A non-zero exit means the write failed.
- `--check` prints the current status and exits non-zero if the item is not on the board. The output starts with the status name (e.g. `Approved`) and may be followed by a parenthetical; match the name exactly and ignore anything after it.

Always attempt `cfwf` rather than deciding in advance that no board is configured: only conclude there is no board if `cfwf` itself reports finding no "Workflow" project linked to the repo, in which case skip board updates silently for the rest of the session.
