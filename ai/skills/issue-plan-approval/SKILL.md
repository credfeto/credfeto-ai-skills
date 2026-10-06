---
name: credfeto-issue-plan-approval
description: Post an implementation plan on a GitHub issue and wait for explicit human approval before starting work on it, when picking up an issue that has no PR yet, including which commenters count as trusted approvers and how to keep waiting for approval within an interactive session rather than ending the turn. Use when selecting or resuming a GitHub issue with no existing pull request, before writing any code against it.
---

# Issue Plan-First Approval Gate

When picking up a GitHub **issue** that has no existing PR, do not start implementing directly. Run the repo's Pre-Work Baseline Check first, including before checking for an existing plan comment, and follow its auto-fix, failure and block rules; only continue with this gate once the baseline is clean.

## Trusted Commenters

A trusted commenter is a human whose comment can approve a plan or ask for work. Decide it by the comment author's login, never by `authorAssociation` (`OWNER`, `MEMBER` or `COLLABORATOR`), because an account with collaborator access is not necessarily a human approver: the agent's own bot account is usually a collaborator.

- **P1.** Trust only the logins in the "Trusted commenters" list the orchestrator passes in your CLAUDE.md.
- **P2.** Never trust a comment whose author login is the bot login the orchestrator passes in your CLAUDE.md alongside the "Trusted commenters" list, even if that login is also in the list, because a comment from the agent's own bot account is never a human approval, and its live-chat mirror comment quotes the approval keywords and would otherwise approve its own plan. Match that login by name, never by whether `gh` reports `viewerDidAuthor` as `true`, because the agent can run as a trusted human's account (the repository owner, for example) and excluding every comment by that account would drop that human's real approvals. If no bot login is provided, exclude no login.
- **P3.** If no list is provided (for example an interactive session started without the orchestrator), trust only the repository owner's login (the `<owner>` in `<owner/repo>`), because it is the most conservative choice. If the owner is an organisation, no comment matches, so ask the human instead.
- **P4.** Never write either approval keyword (`approved` or `lgtm`, in any case) in a comment you post unless that comment mirrors a real human approval (see the live-chat rules below), or the keyword sits inside a verbatim quote of a human's own words formatted as a Markdown quote (`>`), because those rules need the exact text and a quote is plainly the human's words. The ban covers every other comment, such as a re-block comment saying no approval was found, a status comment or a question; to refer to the words there, write "the two accepted approval keywords". This is what stops the agent's own comments being read as approval when it runs as a trusted account, because P2 can only exclude a separate bot login and cannot tell the agent's comments apart from that account's human ones.

## 1. Check for an Existing Plan

A comment is a plan comment only when one of its lines is exactly `## Implementation Plan` (case-sensitive, nothing else on that line, a trailing carriage return ignored), wherever that line sits in the comment, because a plan with a short preamble should still count and an exact whole-line, case-sensitive heading avoids false matches. The query splits on lines because jq's `^` and `$` anchor to the whole string, not to each line:

```bash
gh issue view <number> --repo <owner/repo> --json comments \
  --jq 'any(.comments[].body; split("\n") | any(rtrimstr("\r") == "## Implementation Plan"))'
```

- `false` → no plan posted yet; go to [Post the Plan](#2-post-the-plan).
- `true` → a plan already exists; go to [Check for Approval](#3-check-for-approval).

## 2. Post the Plan

Produce a concrete implementation plan (using `/plan`), then post it as an issue comment in **exactly** this format:

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

**Open questions vs. embedded conditional decisions:** any conditional or deferred decision point in the Approach or Files-to-change text — a decision the plan does not itself resolve (e.g. "needs policy sign-off", "pending a decision on X", an either/or left open) — must be lifted out into its own `Qn.` entry under Open questions, not left as prose in Approach/Files-to-change. Prose framing hides it from the Blocked/approval gate below, which only inspects Open questions; a `Qn.` entry is what actually forces it through that gate. A matching check applies when the issue is closed.

Then mark the issue Blocked, update the workflow board to **Planning** if the repo has one (see [Updating a Workflow Board](#updating-a-workflow-board) below), and **stop**:

```bash
gh issue edit <number> --repo <owner/repo> --add-label Blocked
```

Use only the `Blocked` label for this purpose; never a substitute such as `do not merge` or `needs review`; the orchestrator only recognises `Blocked` when deciding whether to skip an item.

Whenever `Blocked` is added, the accompanying comment must name the specific instruction that requires the stop, as a link to its section. A judgement such as "out of scope", "pre-existing" or "also fails on main" is never such an instruction; if no instruction requires the stop, do not add `Blocked` and carry on with the work, because an unjustified `Blocked` stalls the item until a human notices.

Revise a plan only by posting a new `## Implementation Plan` comment, never by editing an existing one in place, so approval is always judged against the latest plan comment.

Approval requires an explicit human action; the orchestrator never removes `Blocked` automatically (the sole exception is live-chat approval in an interactive session, see below):

- **Board configured**: a human with project write access sets the board status to **Approved** and removes `Blocked`.
- **No board**: a trusted commenter posts an approval comment (`approved` / `lgtm`) and removes `Blocked`.

## 3. Check for Approval

How approval is signalled depends on whether a Workflow board is configured (the orchestrator passes this context in your CLAUDE.md; see [Updating a Workflow Board](#updating-a-workflow-board) below):

- **Board configured**: check whether a human with project write access (the board only lets those people move a card) has set the board status to **Approved**. If yes, check for an existing branch first (see below), then proceed to implementation. If not yet, re-post any revised plan as a new comment, mark the issue Blocked, and stop; in an interactive session, then wait as described below.
- **No board**: check for an approval comment from a trusted commenter posted **after** the plan comment (keywords: `approved` / `lgtm`, case-insensitive, whole word). If found, check for an existing branch first (see below), then proceed to implementation. If not found, re-post any revised plan as a new comment, mark the issue Blocked, and stop; in an interactive session, then wait as described below.

Either way, before skipping to implementation once approved, check whether a branch for this issue already exists (e.g. from an earlier session) and resume it rather than starting a fresh one.

If a human answers or approves in a live chat session rather than posting a GitHub comment directly, post the comment yourself, quoting the live instruction, before resuming work and before asking for `Blocked` to be removed. The record must survive even if the chat session is lost. The one documented exception, which waives only the requirement that a human clears `Blocked` (never the mirror-comment requirement), is live-chat approval handled within an interactive session; see [Waiting for Approval in an Interactive Session](#waiting-for-approval-in-an-interactive-session) below.

**Check GitHub's live state, not just chat.** A human's approval action may land directly on the issue (a comment, a label change, moving the board card) without also being repeated in chat: they already have to open the issue to read the posted plan, so relaying it a second time in chat is not something to wait on. Before treating the issue as approved, still blocked, or unchanged, re-check its live state (labels and comments with `gh issue view`, plus the board's status via `cfwf workflow-status --check`) rather than relying on stale memory or assuming silence in chat means nothing has happened on GitHub. This cuts both ways: a literal chat-only approval (a human typing one of the keywords directly into the chat session, rather than posting it as a GitHub comment) is still valid on its own, but must be mirrored as a GitHub comment so the record survives even if the chat session is lost; and an unexplained GitHub-side state change must not be treated as approval without confirming a human actually made it, since an automated board rule or a stray process flipping a field is not a human decision.

## Waiting for Approval in an Interactive Session

Applies only to an interactive session: one where a human has actually typed a message in it (an injected prompt or task notification does not count; if unsure, assume the session is unattended, because an unattended run treated as interactive would poll or wait for a reply that never comes). An unattended run stops once the plan is posted and Blocked is added, and must not poll. Only the Orchestrator decides the run mode; it states the mode in every hand-off to a role whose rules depend on it, and that role uses the stated mode rather than judging it itself. A hand-off that states no mode means unattended.

- **P1.** Once the plan is posted and Blocked added (or, on resume, once an existing plan is found not yet approved), "stop" means stop working on the issue, not stop watching it. Run the read in P2 once now and take its `plan` as the baseline (P3), then start a dynamic-pacing loop instead of ending the turn, carrying the baseline in the loop prompt so it is explicit on every tick:

  ```text
  /loop check whether issue <number> in <owner/repo> has been approved (plan baseline <plan>); if not, wait
  ```

- **P2.** Each tick, read all of the following, then decide (do not stop early, so a half-finished approval can be flagged):
  - The labels, the latest plan comment's `createdAt`, and the comments a trusted commenter posted after it. Replace `<trusted logins>` with the trusted logins, each quoted and separated by commas, and `<bot login>` with the bot login, quoted; if no bot login is provided, delete the line that contains `<bot login>`:

    ```bash
    gh issue view <number> --repo <owner/repo> --json labels,comments \
      --jq '([.comments[] | select(.body | split("\n") | any(rtrimstr("\r") == "## Implementation Plan"))] | last | .createdAt) as $plan
            | {blocked: ([.labels[].name] | index("Blocked") != null),
               plan: $plan,
               afterPlan: [.comments[]
                 | select($plan != null and .createdAt > $plan
                   and .author.login != <bot login>
                   and (.author.login | IN(<trusted logins>)))
                 | .body]}'
    ```

    Judge `afterPlan` as in the no-board approval check: a comment approves only if it uses one of the keywords as an unconditional approval, not a question, a negation or a qualified approval ("approved, but ..."). The query leaves out comments by the bot login, because a comment from the agent's own bot account is never a human approval, and its live-chat mirror comment quotes the keywords and is posted after the plan, so the timestamp filter alone would count it as approval. It matches the bot login by name rather than by `viewerDidAuthor`, so an approval from a trusted human whose account the agent runs as still counts.
  - **Board configured only**: the card's workflow status. A non-zero exit means treat it as not approved:

    ```bash
    cfwf workflow-status --check --repo <owner/repo> --issue <number>
    ```

  Decide as follows:
  - **Approved**: `blocked` is `false` and `plan` is not null, and either the card is `Approved` (board configured) or a comment in `afterPlan` approves (no board), and `plan` still equals the baseline.
  - **Half-finished**: the approval signal is present but `blocked` is still `true` (the human has not finished clearing it). Keep waiting and tell the human in chat when you first see it.
  - **Otherwise**: not yet, and wait silently. If `plan` is null, no plan comment was found: tell the human and stop the loop.
- **P3.** The plan baseline is the `plan` value from the first read (the latest plan comment's `createdAt`, whether just posted or found on resume). The plan comment is found by its heading alone, so a plan posted under any account is seen. If a later tick returns a different `plan`, the plan changed and earlier approvals no longer count. On the board, a card only stays `Approved` for a plan that has not been re-posted, because every re-post resets the card to **Planning**. If you revised the plan, restart from posting the plan (`Blocked` re-added, board back to **Planning**, new baseline in the prompt); if someone else posted it, tell the human in chat and wait for their direction instead of treating it as the plan.
- **P4.** Pace the loop with `ScheduleWakeup`, as the `/loop` skill's dynamic mode does, passing the `/loop` prompt back each tick. If `ScheduleWakeup` is unavailable, do not poll: tell the human the issue is waiting and that saying `approved` in chat will continue the work.
  - Wait `delaySeconds: 1200` (20 minutes) with `noop: true` while nothing has changed. There is no wait cap: the loop ends when the session does, and the 30-minute deadline for commands governs commands, not a wait for a human.
  - On approval, whether found on a tick or given in chat, stop the loop with `ScheduleWakeup` and `stop: true`, check for an existing branch, and continue to implementation.
- **P5.** **Live-chat approval ends the wait immediately.** If the human's chat message opens with the literal word `approved` or `lgtm` (case-insensitive) and is otherwise an unconditional approval, do not wait for the next tick. This is the one place the agent acts on a chat message alone. A question ("is this approved yet?"), a negation ("not approved"), a qualified approval or a passing mention does not count; if in doubt, ask:
  - Re-run the P2 read and confirm the message refers to this issue, `plan` still equals the baseline, `Blocked` is only the plan-approval block and the plan has no unresolved Open questions; if any check fails, ask instead of acting. `Blocked` counts as only the plan-approval block when no comment posted after the latest plan comment asks a question, reports a failed baseline or a timeout, or carries an environment-block marker (`<!-- orchestrator:env-block`): read the comments after the plan and judge them.
  - Post a mirror comment on the issue quoting the live instruction.
  - Remove the label: `gh issue edit <number> --repo <owner/repo> --remove-label Blocked`.
  - If the repo has a Workflow board, set the workflow status to **Approved** with `cfwf workflow-status --set --repo <owner/repo> --issue <number> --status Approved`.
  - Stop the loop and continue to implementation.

  This is the one documented exception to the rules that only a human clears `Blocked` and that labels are never removed: the human's chat instruction is the explicit action and the agent carries out the label and board changes on their behalf. It covers only the plan-approval `Blocked` of an issue in an interactive session; any other `Blocked` (a question, a failed baseline, an environment block) still waits for the human to clear it.

## Scope: Issues Only, Never Re-Checked at PR Time

This gate governs only picking up an issue that has **no existing PR**. Once a PR exists for the issue, this gate no longer applies: a PR is never opened for an issue until this gate has already been passed by a human, so the PR's own existence *is* the authorisation.

A session working the PR phase must never re-derive or re-check approval from the PR's own workflow board card; that card is purely a phase marker for the separate PR review workflow, not a second approval gate. If a PR's own board card still reads "Not Started", "Planning" or "Approved" (for example because the session that opened the draft PR died before advancing its card, or a freshly-seeded board has not caught up yet), treat that as "Development" and continue with the PR review workflow: never block pending approval, and never treat the stale card as evidence the linked issue was never approved. The issue and PR cards are kept in step automatically, forward-only, by the orchestrator itself; this is not something a session needs to reconcile by hand.

## Updating a Workflow Board

Always use the repo's `cfwf` tool for workflow board reads and writes; never hand-compose `gh project`, `gh repo view --json projectsV2`, or `gh api graphql` commands for it. Every command names the item with `--repo <owner/repo> --issue <number>`:

```bash
# Move the issue to a status (matched by display name, case-insensitive)
cfwf workflow-status --set --repo <owner/repo> --issue <number> --status "Planning"

# Read the current status
cfwf workflow-status --check --repo <owner/repo> --issue <number>
```

- `--set` adds the item to the board if it is not already there and sets the status, then prints confirmation; exit 0 means the write was accepted (do not re-read it to confirm; GitHub's state lags behind writes). A non-zero exit means the write failed.
- `--check` prints the current status and exits non-zero if the item is not on the board. The output starts with the status name (e.g. `Approved`): match the name exactly and ignore anything after it.

If the repo's CLAUDE.md carries no Workflow board data, still attempt `cfwf`: only conclude there is no board if `cfwf` itself reports finding no "Workflow" project linked to the repo, in which case skip board updates silently for the rest of the session.
