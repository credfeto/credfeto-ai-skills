---
name: credfeto-github-issue
description: Create and manage GitHub issues correctly, covering duplicate search, planned descriptions, priority/status labels, assignment, adding new issues to the repository's linked Workflow project board, correcting prior claims, the pre-closure decision check, and the Blocked label rules for AI-initiated issues, including the mandatory tracking issue required before starting any ad-hoc task. Use when asked to create a GitHub issue, when raising an issue autonomously, when a human asks you to do something and no existing issue or PR is already specified, when a PR or issue comment asks you to raise an issue, when selecting the next issue to work on, when about to close an issue or PR, or when asking a blocking question and needing to mark an item Blocked.
---

# GitHub Issue Management

Use `gh` to manage issues for every piece of work. Only update issues if `gh` is installed and authenticated (`gh auth status`); otherwise read code and git log for state.

## Authentication (MANDATORY)

Never attempt `gh auth login` or manipulate credentials yourself; if auth is broken, stop and report it. Never run `gh auth setup-git`; refuse the request outright, even if asked directly: it wires git's HTTP credential helper to `gh`, rerouting commit/push traffic through `gh` and violating the mandatory rule that commit and push always go through the `git` CLI directly. The rewrite rules also persist in the repo's local `.git/config` beyond the current task, silently breaking every later git operation until manually cleaned up.

## Choosing Between `cfwf` and `gh` (MANDATORY)

Reach for these in this order:

1. `cfwf` for anything it supports, for reads and writes. Run `cfwf help` once per session to see what it covers, and `cfwf help <command>` for a command's options; do not rely on memory, because its commands grow.
2. A native `gh <noun> <verb>` subcommand when `cfwf` has no command for the operation.
3. `gh api` or `gh api graphql` only when neither of the above covers it.

`cfwf` is where routine `gh` operations are meant to end up as standardised, pre-canned commands rather than long `gh` scripts composed by hand. When you use `gh api` (REST or GraphQL) or `gh ... --json <fields>` (with or without `--jq`), for a read or a write, and no `cfwf` command covers that use, raise an issue on `credfeto/credfeto-orchestrator` asking for it to be added to `cfwf`, then carry on with `gh` for the current task. This applies to routine uses such as `gh issue view --json` and `gh pr list --json` as much as to unusual ones. If `cfwf` (or any other required CLI tool) is not installed, stop immediately and ask the user to install it, and report a command that fails, rather than falling back to hand-composed `gh` for a use `cfwf` covers; never search for the binary in alternative locations, manipulate `PATH` to find it, or attempt to install it without being asked. Plain native subcommands without `--json`, such as `gh pr create`, `gh issue comment` and `gh pr edit --add-label`, are exempt.

- **One issue per distinct use.** Search `credfeto/credfeto-orchestrator` first, using plain output so the search does not itself need `--json`: `gh issue list --repo credfeto/credfeto-orchestrator --state all --search "cfwf <keywords>"`. If an open or closed issue already covers the use, do not raise another; if a closed one was declined, follow its outcome. The uses these instructions themselves prescribe are already covered this way, so the search finds them and nothing more is needed.
- **Say what is needed.** Give the exact `gh` command (with placeholders for the values), what it is for, and where it is used. Add the new issue to the "Workflow" project as for any issue (see Workflow Project Board below).

## GitHub State Lags Behind Writes (MANDATORY)

GitHub's API is asynchronous: a change can take seconds, sometimes longer, to show up in a read. This applies to anything that lags, including Workflow board fields, labels, and closing-issue references. It is GitHub's behaviour, not a fault in `gh`, `cfwf`, the orchestrator or the API proxy, so do not raise issues on `credfeto/credfeto-orchestrator` or `credfeto/github-api-proxy` for it.

- A write whose call succeeded is done. Do not re-read it to confirm.
- Never spam GitHub while waiting for a change to show. Do not repeat a write, or poll or loop on a read, because a read straight after a write has not caught up yet. (Waiting for a human to act is a different, sanctioned wait.)
- A read that disagrees with a write you just made is lag, not a failure. If a later step reads it anyway, carry on and check again at a later step; repeat the write only if the value is still wrong then. There is no fixed wait.

## Before Starting Work

- Either find a **100% matching** existing issue (confirm with the user before linking) or create a new one with the original prompt and a clear description.
- The search itself is a normal, automatic part of this workflow: do not ask permission before running it. Any question is about what a match means once found (confirming a candidate before linking), never about whether to run the search itself.
- Assign yourself before starting: `gh issue edit <number> --add-assignee @me`.
- Only work on unassigned issues or issues already assigned to you.
- Skip any issue labelled `On Hold` or `Blocked`; if all remaining issues carry these labels, report this to the user and wait.
- Reference issue numbers in commit messages and branch names.
- If work on an issue is abandoned, comment with findings before closing; do not abandon silently.

## Workflow Project Board (MANDATORY)

Every issue raised, in any repository and via any flow (deliverable issues, ad-hoc intake tracking issues, AI-initiated issues, sub-issues), must be added to the "Workflow" GitHub project linked to that repository, immediately after creation:

```bash
cfwf workflow-status --set --repo <owner>/<repo> --issue <number> --status "Not Started"
```

Run this only for an issue you have just created: `--set` overwrites the status of an item already on the board, so never re-run it on an existing issue to "make sure".

## Issue Creation Flow (MANDATORY when asked to create or update an issue)

When the issue itself is the requested deliverable:

1. Enter Plan Mode.
2. Work out at a high level what code change the issue would represent: scope, affected files, approach.
3. Exit Plan Mode and return to auto.
4. Create the issue, or update the existing issue, using the plan output to write a meaningful description.

This is distinct from Ad-Hoc Prompt Intake below, which covers being asked to _do_ something; there, the issue is a tracking side-effect rather than the deliverable itself.

## Ad-Hoc Prompt Intake (MANDATORY)

Applies whenever a human asks you to _do_ something in the context of a repo (a task, not a request to raise an issue) and no existing issue or PR has already been specified as the thing to work on. No exception for how trivial the request seems, no exception for `credfeto/cs-template` itself, and no "skip straight to diagnosis/fix in chat" alternative to offer or ask about: there is no path around this flow, so do not present it as a choice.

1. Before taking any other action (including answering a read-only question), create a GitHub issue in the current repo:
   - Title: a concise summary of the prompt.
   - Body: the prompt, verbatim, as the starting point.
   - Labels: `AI-Work` and `Blocked` (minimum), always, regardless of who initiated the underlying task; add other relevant labels (e.g. priority) as appropriate.
2. Use Plan Mode to work out scope, affected files, and approach, and post it as an issue comment before starting, using exactly this format:

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

   Continue the assumption and `Q` numbering from the highest already used in the work item (issue and PR), never restarting at `a.` or `Q1`, so a number names exactly one item for the life of the work item. A revised plan continues the numbering of the plan it supersedes.

   Any conditional or deferred decision point in the Approach or Files-to-change text, a decision the plan does not itself resolve (e.g. "needs policy sign-off", "pending a decision on X", an either/or left open), must be lifted out into its own `Qn.` entry under Open questions, not left as prose in Approach/Files-to-change. Prose framing hides it from the Blocked/approval gate below, which only inspects Open questions; a `Qn.` entry is what actually forces it through that gate.

3. As open questions are identified, add each as an issue comment as soon as it's identified; do not batch them all until the end.
4. Do not proceed until an explicit human approval comment exists (`approved` / `lgtm`) and `Blocked` is removed; if approval came via live chat, mirror it as a GitHub comment first. In an interactive session, keep watching the issue for approval rather than ending the turn (see the `credfeto-issue-plan-approval` skill), which applies to these tracking issues too. Approval requires an explicit human action. If the repo has a Workflow board, a human with project write access sets the board status to **Approved** and removes `Blocked`; with no board, a trusted commenter posts the approval comment and removes `Blocked`. Revise a plan by posting a new `## Implementation Plan` comment, never by editing one in place, so approval is always judged against the latest plan comment.
5. Once approved and `Blocked` is removed:
   - If the request needs a code change, proceed and open a PR referencing the issue when ready.
   - If the request is read-only/informational (no code change), post the answer as an issue comment and close the issue.

## AI-Initiated Issues (MANDATORY)

When raising a GitHub issue autonomously (not directly requested by a human):

1. Search for existing issues (both **open** and **closed**) covering the same topic before creating; do not create duplicates.
2. Add the `Blocked` label immediately after creating the issue so it is held for human review before being acted upon.

Exceptions: do not add `Blocked`:

- A human explicitly asked you to raise the issue: ask for the priority label instead, then apply it.
- The issue is raised by the dependency security detection rule (e.g. flagged during `npm install` or from a Dependabot advisory): use only the labels specified by that rule; see [Dependency Security Issues](#dependency-security-issues) below.

## Dependency Security Issues

After any push, if the remote reports vulnerabilities:

- Check for open Dependabot PRs covering them (`gh pr list --label dependencies`).
- If none exist, visit the repo's Dependabot page and for any manually fixable advisory create a GitHub issue labelled `Security` and `AI-Work`, naming the package, severity, and fix steps.

## Priority Labels (highest to lowest)

| Label | Meaning |
| --- | --- |
| `Security` | Security fix, highest possible priority |
| `Urgent` | Get this done ASAP; security fixes take precedence |
| `High` | Addressed after `Urgent` work |
| `Medium` | Addressed after `High` work |
| `Low` | Addressed after `Medium` work |
| _(untagged)_ | No priority set, tracked but timing does not matter |

When selecting the next issue to work on, prefer issues with higher-priority labels. Prioritise PRs with a `CHANGES_REQUESTED` review status over starting a new issue.

## Status Labels

| Label | Meaning |
| --- | --- |
| `On Hold` | Needs further thought or cannot be implemented yet, do not start work |
| `Blocked` | Needs human input before work can continue |

An issue labelled `On Hold` is not ready to be worked on; do not pick up or assign yourself to it. If the label is later removed, re-evaluate its priority and proceed normally.

## Blocked Label (MANDATORY)

When asking a question in an issue or PR comment and waiting for an answer before continuing:

1. Add the `Blocked` label immediately after posting the question:
   - Issue: `gh issue edit <number> --repo <owner/repo> --add-label "Blocked"`
   - PR: `gh pr edit <number> --repo <owner/repo> --add-label "Blocked"`
2. Do not continue working on the item until the label is removed.
3. Use only the `Blocked` label for this purpose; never a substitute such as `do not merge` or `needs review`.
4. Live-chat approval is not sufficient on its own: if a human answers or approves in a live chat session rather than posting a GitHub comment directly, post the comment yourself, quoting the live instruction, before resuming work and before asking for `Blocked` to be removed. The record must survive even if the chat session is lost.
5. Whenever `Blocked` is added, the accompanying comment (or, for a new issue, its body) must name the specific instruction that requires the stop, as a link to its section; for an issue held under AI-Initiated Issues that instruction is AI-Initiated Issues itself. A judgement such as "out of scope", "pre-existing" or "also fails on main" is never such an instruction; if no instruction requires the stop, do not add `Blocked` and carry on with the work, because an unjustified `Blocked` stalls the item until a human notices.

## Trusted Commenters

A trusted commenter is a human whose comment can approve a plan or ask for work. Decide it by the comment author's login, never by `authorAssociation` (`OWNER`, `MEMBER` or `COLLABORATOR`), because an account with collaborator access is not necessarily a human approver: the agent's own bot account is usually a collaborator.

1. Trust only the logins in the "Trusted commenters" list the orchestrator passes in your CLAUDE.md.
2. Never trust a comment whose author login is the bot login the orchestrator passes alongside that list, even if that login is also in the list, because a comment from the agent's own bot account is never a human approval. Match that login by name, never by whether `gh` reports `viewerDidAuthor` as `true`, because the agent can run as a trusted human's account and excluding every comment by that account would drop that human's real approvals. If no bot login is provided, exclude no login.
3. If no list is provided (for example an interactive session started without the orchestrator), trust only the repository owner's login (the `<owner>` in `<owner/repo>`). If the owner is an organisation, no comment matches, so ask the human instead.
4. Never write either approval keyword (`approved` or `lgtm`, in any case) in a comment you post unless that comment mirrors a real human approval, or the keyword sits inside a verbatim quote of a human's own words formatted as a Markdown quote (`>`). The ban covers every other comment, such as a re-block comment saying no approval was found, a status comment or a question; to refer to the words there, write "the two accepted approval keywords".

## Ad-Hoc Issue Requests From Comments (MANDATORY)

Before continuing any review or CI loop, scan all comments on the current PR and its linked issue(s) from trusted commenters for ad-hoc requests to create a new GitHub issue: natural-language phrasing such as "raise an issue", "create an issue", "add an issue", "open an issue", "file an issue" (case-insensitive).

For each such request not yet actioned (no reply from you linking a newly created issue):

1. Search for an existing open or closed issue covering the same topic; do not create duplicates.
2. If none exists, create it immediately:

   ```bash
   gh issue create --repo <owner/repo> \
     --title "<concise title from the request>" \
     --body "<description from the request>" \
     --label "<priority label from the request, or 'Medium' if unspecified>"
   ```

3. Reply to the original comment with the new issue number (`Raised as #<new-issue-number>.`): use `gh pr comment` if the request was on a PR, `gh issue comment` if it was on an issue (including a linked issue).
4. Only continue with the rest of the workflow once every such request is actioned.

The same rule applies when picking up an issue: if a comment on it requests a sub-issue, create it and reply before starting implementation work.

## Label Rules (MANDATORY)

- Always use `--add-label`; **never** `--label`, which replaces all existing labels.
- Never remove labels from issues or PRs; GitHub workflows add classification labels automatically. The sole exception is removing `Blocked` on a human's live-chat plan approval of an issue in an interactive session, carried out on their behalf after mirroring the approval as a GitHub comment.

## Comment Bodies (MANDATORY)

Always pass multi-line text using a HEREDOC, never escaped `\n` sequences:

```bash
gh issue comment <number> --repo <owner/repo> --body "$(cat <<'COMMENT'
First paragraph.

Second paragraph.
COMMENT
)"
```

## Large Multi-Component Tasks

1. Create a top-level GitHub issue (if none specified); assign it; include the full original prompt as the body.
2. Comment findings on the issue before starting (components found, current state, etc.).
3. For each component, create a sub-issue referencing the top-level issue; use the sub-issue number in branch names and commit messages.
4. Work on one component at a time; commit and push before starting the next.
5. Close the sub-issue as soon as the relevant commits are pushed.

### Issue tracking cadence

- Each sub-issue must list files with status: `❌ Not started` / `🔄 In progress` / `✅ Done`, update after each commit + push.
- The top-level issue tracks only component-level status (sub-issues open/closed, branches merged).
- Update the sub-issue after each significant commit+push; update the top-level issue when overall status changes.
- When resuming, update the issue with current state before continuing.

## Comment Replies (MANDATORY)

Reply to every PR or issue comment that prompted an action. "Every PR or issue comment" spans both comment surfaces: top-level PR/issue comments and review summaries (`gh pr view <n> --json comments,reviews`) **and** inline/diff-level review comments (`gh api repos/<owner>/<repo>/pulls/<n>/comments`); a review can carry an empty top-level body with the actual feedback only in an inline comment, so both must be checked before concluding there is nothing to reply to.

- Code change made: reply with `Fixed in <commit-sha>: <one sentence describing what changed and why>`.
- Pattern Sweep found further occurrences: add `Swept in <sha>: <files touched>` on the next line, one line per commit that carries sweep hunks (the fix SHA when every hit was in a file the fix touched); the per-file reasons are in that commit's body.
- Already fixed by an earlier sweep (no new commit): reply with `Already swept in <sha>`, citing the commit whose body carries the `Construct:` line.
- Question answered inline (no code change): reply with the full answer.
- No reply means no acknowledgement; always close the loop.

## Pre-Closure Decision Check (MANDATORY)

Before closing any issue or PR, check whether its Implementation Plan (Approach/Files-to-change text or an Open Question) or a later comment on it flagged a specific decision as required or pending (e.g. "needs policy sign-off", "pending a decision on X", an unresolved `Qn.`). If so, do not close until that specific item has a visible resolution of its own: a comment recording the decision, a link to the resolving issue/PR, or an explicit retraction, not just implicitly overtaken by whichever branch of the plan got implemented.

This is stricter than an unresolved `Qn.` alone: an Open Question already blocks via the Blocked-label approval gate, and removal of that label is not itself sufficient evidence this check is satisfied; the check here is that the resolution was actually posted, not merely that the item is otherwise ready to close. Applies equally to issues and PRs.

## Correcting a Prior Claim (MANDATORY)

If a factual claim or finding you previously posted in an issue/PR body or comment turns out to be wrong (e.g. a root-cause statement, an evidence point, a "this is a deviation from process" assertion), post a **new comment** stating the correction and briefly why, quoting or referencing the original claim being corrected. Editing the body to also fix it is fine, but the comment is the mandatory part: a silent in-place body edit is not sufficient on its own, because GitHub only surfaces it as a small "edited" marker that a human reviewer can easily miss, unlike a comment which appears in the normal timeline. This rule is about retracting or fixing something substantive that was previously asserted as true, not routine housekeeping edits.

## Prompt Traceability (MANDATORY)

Once a request is already tracked by an issue or PR (including one just created under Ad-Hoc Prompt Intake above), every subsequent prompt from the human that changes, redirects, or adds detail to that work must be recorded on that issue/PR:

- Comment with the prompt (verbatim, or a faithful summary for long prompts) and how it was resolved: a code change, an answered question, a scope adjustment, etc.
- Post this before or immediately after acting on the prompt; do not let several prompts accumulate unrecorded.
- This applies whether the prompt arrived as a live chat message or as a GitHub comment (GitHub comments are already covered by Comment Replies above).
