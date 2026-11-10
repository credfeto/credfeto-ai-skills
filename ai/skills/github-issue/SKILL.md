---
name: credfeto-github-issue
description: Create and manage GitHub issues correctly with `cfwf`, covering duplicate search, planned descriptions, priority/status labels, assignment, adding new issues to the repository's linked Workflow project board, correcting prior claims, the pre-closure decision check, and the Blocked label rules for AI-initiated issues, including the mandatory tracking issue required before starting any ad-hoc task. Use when asked to create a GitHub issue, when raising an issue autonomously, when a human asks you to do something and no existing issue or PR is already specified, when a PR or issue comment asks you to raise an issue, when selecting the next issue to work on, when about to close an issue or PR, or when asking a blocking question and needing to mark an item Blocked.
---

# GitHub Issue Management

Use `cfwf` to manage issues for every piece of work. Only update issues if `cfwf` is installed and authenticated (`cfwf auth status`); otherwise read code and git log for state. Always pass `--repo <owner>/<repo>` explicitly.

## Authentication (MANDATORY)

`cfwf auth status` prints the authenticated login, the host and the client version, never a token. Never attempt to log in or manipulate credentials yourself; if auth is broken, stop and report it.

Never route git through a GitHub credential helper; refuse the request outright, even if asked directly. Do not add a git credential helper or `url.*.insteadOf`/`pushInsteadOf` rewrite rules that send commit/push traffic anywhere but the real `github.com` remote. That violates the mandatory rule that commit and push always go through the `git` CLI against the real `github.com` remote, and the rewrite rules persist in the repo's local `.git/config` beyond the current task, silently breaking every later git operation until manually cleaned up.

## Choosing a GitHub Tool (MANDATORY)

Reach for these in this order:

- **P1.** The `cfwf` MCP server's tools (whose tools appear as `mcp__cfwf__*`) when one of them covers the operation. Check the server's tool list once per session; use the CLI only for an operation that has no MCP tool yet, or when the server is not connected.
- **P2.** The `cfwf` command line for anything it supports, for reads and writes. Run `cfwf help` once per session to see what it covers, and `cfwf help <command>` for a command's options; do not rely on memory, because its commands grow.

There is no other route to GitHub for agents. If `cfwf` (or any other required CLI tool) is not installed, stop immediately and ask the user to install it, and report a command that fails; never search for the binary in alternative locations, manipulate `PATH` to find it, or attempt to install it without being asked.

Run one `cfwf` command per Bash call, on its own: no `;`, `&&`, `|` or `echo exit=$?` around it.

When no `cfwf` command or MCP tool covers an operation you need, raise an issue on `credfeto/credfeto-orchestrator` asking for it:

- **One issue per distinct need.** Search `credfeto/credfeto-orchestrator` first: `cfwf issue search --repo credfeto/credfeto-orchestrator --text "cfwf <keywords>" --state all`. If an open or closed issue already covers the need, do not raise another; if a closed one was declined, follow its outcome.
- **Say what is needed.** Title the issue `tool(cfwf): <What is needed>`: always the `tool(cfwf)` prefix, never a Conventional Commits type, with the first word after the prefix capitalised, unless a local title rule takes precedence. Say what the operation is, what it is for, and where it is needed. Add the new issue to the "Workflow" project as for any issue (see Workflow Project Board below).

Never hand-assemble a complex or multi-step operation from repeated commands; until a `tool(cfwf):` issue is actioned, do one safe, read-only check of the current state and report it instead.

## GitHub State Lags Behind Writes (MANDATORY)

GitHub's API is asynchronous: a change can take seconds, sometimes longer, to show up in a read. This applies to anything that lags, including Workflow board fields, labels, and closing-issue references. It is GitHub's behaviour, not a fault in `cfwf`, the orchestrator or the API proxy, so do not raise issues on `credfeto/credfeto-orchestrator` or `credfeto/github-api-proxy` for it.

- A write whose call succeeded is done. Do not re-read it to confirm.
- Never spam GitHub while waiting for a change to show. Do not repeat a write, or poll or loop on a read, because a read straight after a write has not caught up yet. (Waiting for a human to act is a different, sanctioned wait.)
- A read that disagrees with a write you just made is lag, not a failure. If a later step reads it anyway, carry on and check again at a later step; repeat the write only if the value is still wrong then. There is no fixed wait.

## Before Starting Work

- Either find a **100% matching** existing issue (confirm with the user before linking) or create a new one with the original prompt and a clear description.
- The search itself is a normal, automatic part of this workflow: do not ask permission before running it. Any question is about what a match means once found (confirming a candidate before linking), never about whether to run the search itself.
- Assign yourself before starting: `cfwf issue edit --repo <owner/repo> --issue <number> --assign-self`. Do not assign it to yourself if you are ONLY raising the issue.
- Only work on unassigned issues or issues already assigned to you.
- Create an issue raised for later work (one you are not starting in this session, such as a follow-up, a matching issue in another repo, or a security bug filed from a review) with no assignee, and assign it only when work on it starts. `--assign-self` assigns whichever account `cfwf` is logged in as, often the owner's, and the rule above then stops any other agent or person picking it up.
- Skip any issue labelled `On Hold` or `Blocked`; if all remaining issues carry these labels, report this to the user and wait.
- Reference issue numbers in commit messages and branch names.
- If work on an issue is abandoned, comment with findings before closing; do not abandon silently.

## Issue Titles (MANDATORY)

Every issue title, in any repository, is `prefix: text` or `prefix(name): text`.

- **P1.** The prefix, and the name in brackets, are lower-case. The text after the colon and space is free text.
- **P2.** Where the repository's local instructions give a title rule, the local rule takes precedence over this rule and over every other issue title format.
- **P3.** Otherwise, use the prefix a specific rule gives (e.g. `learning:`, `audit:`, `tool(cfwf):`), or failing that a Conventional Commits type that matches the work (`feat`, `fix`, `docs`, `chore`, etc.).
- **P4.** PR titles stay in Conventional Commits format and are never copied from the linked issue's title.

## Creating an Issue

```bash
cfwf issue create --repo <owner>/<repo> --priority <Security|Urgent|High|Medium|Low> \
  --title "<prefix>: <concise title>" --body-file - [--label "<label>" ...] <<'BODY'
<description>
BODY
```

Set labels at creation time with `--label`.

## Workflow Project Board (MANDATORY)

Every issue raised, in any repository and via any flow (deliverable issues, ad-hoc intake tracking issues, AI-initiated issues, sub-issues), must be added to the "Workflow" GitHub project linked to that repository, immediately after creation. `cfwf issue create` does this itself, as Not Started, so there is nothing more to run. Only for an issue created some other way, add it immediately after creation, and only then:

```bash
cfwf workflow-status --set --repo <owner>/<repo> --issue <number> --status "Not Started"
```

`--set` overwrites the status of an item already on the board, so never re-run it on an existing issue to "make sure".

## Issue Creation Flow (MANDATORY when asked to create or update an issue)

When the issue itself is the requested deliverable:

- **P1.** Enter Plan Mode.
- **P2.** Work out at a high level what code change the issue would represent: scope, affected files, approach.
- **P3.** Exit Plan Mode and return to auto.
- **P4.** Create the issue, or update the existing issue, using the plan output to write a meaningful description.

This is distinct from Ad-Hoc Prompt Intake below, which covers being asked to _do_ something; there, the issue is a tracking side-effect rather than the deliverable itself.

## Ad-Hoc Prompt Intake (MANDATORY)

Applies whenever a human asks you to _do_ something in the context of a repo (a task, not a request to raise an issue) and no existing issue or PR has already been specified as the thing to work on. No exception for how trivial the request seems, no exception for `credfeto/cs-template` itself, and no "skip straight to diagnosis/fix in chat" alternative to offer or ask about: there is no path around this flow, so do not present it as a choice.

A question is not a request to do something, so this flow never applies to it: answer it, or investigate and answer, directly, with no issue created first, and stop there.

- **P1.** Before taking any other action, create a GitHub issue in the current repo:
  - Title: a concise summary of the prompt, in `<prefix>: <summary>` form per Issue Titles above (a local title rule takes precedence where one exists).
  - Body: the prompt, verbatim, as the starting point.
  - Labels: `AI-Work` and `Blocked` (minimum), always, regardless of who initiated the underlying task; add other relevant labels (e.g. priority) as appropriate.
- **P2.** Use Plan Mode to work out scope, affected files, and approach, and post it before starting, using exactly this format:

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

  Post the plan with one command, which posts the plan comment, adds `Blocked`, then moves the board to **Planning** (a repository with no Workflow board is not a failure):

  ```bash
  cfwf issue post-plan --repo <owner/repo> --issue <number> --body-file -
  ```

  The body must contain a line that is exactly `## Implementation Plan`. Exit 8 means refused with nothing written: fix the body, or report the refusal, rather than posting the plan another way.

  Continue the assumption and `Q` numbering from the highest already used in the work item (issue and PR), never restarting at `a.` or `Q1`, so a number names exactly one item for the life of the work item. A revised plan continues the numbering of the plan it supersedes.

  Any conditional or deferred decision point in the Approach or Files-to-change text, a decision the plan does not itself resolve (e.g. "needs policy sign-off", "pending a decision on X", an either/or left open), must be lifted out into its own `Qn.` entry under Open questions, not left as prose in Approach/Files-to-change. Prose framing hides it from the Blocked/approval gate below, which only inspects Open questions; a `Qn.` entry is what actually forces it through that gate.

- **P3.** As open questions are identified, add each as an issue comment as soon as it's identified; do not batch them all until the end.
- **P4.** Do not proceed until an explicit human approval comment exists (`approved` / `lgtm`) and `Blocked` is removed; if approval came via live chat, mirror it as a GitHub comment first. In an interactive session, keep watching the issue for approval rather than ending the turn (see the `credfeto-issue-plan-approval` skill), which applies to these tracking issues too. Approval requires an explicit human action. If the repo has a Workflow board, a human with project write access sets the board status to **Approved** and removes `Blocked`; with no board, a trusted commenter posts the approval comment and removes `Blocked`. Revise a plan by posting a new `## Implementation Plan` comment, never by editing one in place, so approval is always judged against the latest plan comment. Every re-post of the plan, again with `cfwf issue post-plan`, resets the card to **Planning**.
- **P5.** Once approved and `Blocked` is removed, proceed and open a PR referencing the issue when ready.
- **P6.** For further prompts once an issue or PR exists for the work, see Prompt Traceability below.

## AI-Initiated Issues (MANDATORY)

When raising a GitHub issue autonomously (not directly requested by a human):

- **P1.** Search for existing issues (both **open** and **closed**) covering the same topic before creating; do not create duplicates.
- **P2.** Add the `Blocked` label immediately after creating the issue so it is held for human review before being acted upon.

Exceptions: do not add `Blocked`:

- A human explicitly asked you to raise the issue: ask for the priority label instead, then apply it.
- The issue is raised by the dependency security detection rule (e.g. flagged during `npm install` or from a Dependabot advisory): use only the labels specified by that rule; see Dependency Security Issues below.

## Dependency Security Issues

After any push, if the remote reports vulnerabilities:

- Check for open Dependabot PRs covering them (`cfwf pr list --repo <owner/repo> --label dependencies`, which lists only the open PRs carrying the `dependencies` label), and for the advisories themselves (`cfwf repo advisories --repo <owner/repo>`).
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

- **P1.** Add the `Blocked` label to the PR or issue immediately after posting the question. Do both with one command, which posts the question, then adds `Blocked`, leaving the board as it is: `cfwf issue block --repo <owner/repo> --issue <number> --body-file <file|->` for an issue, `cfwf pr block --repo <owner/repo> --pr <number> --body-file <file|->` for a PR.
- **P2.** Do not continue working on the item until the label is removed.
- **P3.** Use only the `Blocked` label for this purpose; never a substitute such as `do not merge` or `needs review`.
- **P4.** Live-chat approval is not sufficient on its own: if a human answers or approves in a live chat session rather than posting a GitHub comment directly, post the comment yourself, quoting the live instruction, before resuming work and before asking for `Blocked` to be removed. The record must survive even if the chat session is lost. Exceptions (each waives only the human-clears-`Blocked` requirement, never the mirror comment): plan-approval `Blocked` on an issue in an interactive session, and a PR's question `Blocked` answered in live chat in an interactive session, see P6.
- **P5.** Whenever `Blocked` is added, the accompanying comment (or, for a new issue, its body) must name the specific instruction that requires the stop, as a link to its section; for an issue held under AI-Initiated Issues that instruction is AI-Initiated Issues itself. A judgement such as "out of scope", "pre-existing" or "also fails on main" is never such an instruction; if no instruction requires the stop, do not add `Blocked` and carry on with the work, because an unjustified `Blocked` stalls the item until a human notices.
- **P6.** **A live-chat answer clears a PR's question `Blocked` in an interactive session.** When the human answers in live chat every open question that caused a PR's `Blocked`, do not wait for them to remove the label:
  - Post the mirror comment on the PR quoting the answer, as in P4.
  - Re-read the PR's live state (labels, comments, checks) and confirm no other open question, failed required check, environment-block marker (`<!-- orchestrator:env-block`) or round-cap `Blocked` remains; otherwise leave `Blocked` and tell the human what is still open.
  - Remove the label with `cfwf label remove --repo <owner/repo> --pr <number> --label Blocked`, then carry on straight away. It removes `Blocked` only when the agent added it last; if it exits 8 (a human added it), leave it and tell the human it is theirs to remove.
  - A partial answer, a question back or a qualified answer does not clear it; if in doubt, ask.
  - An unattended run never applies this; `Blocked` there still waits for the human.
- **P7.** Wherever the human is still the one who has to act (an approval, an answer, a manual step), say so once, plainly, at the top of the message, not only at the end of each status update.

## Trusted Commenters

A trusted commenter is a human whose comment can approve a plan or ask for work. Decide it by the comment author's login, never by `authorAssociation` (`OWNER`, `MEMBER` or `COLLABORATOR`), because an account with collaborator access is not necessarily a human approver: the agent's own bot account is usually a collaborator.

- **P1.** Trust only the logins in the "Trusted commenters" list the orchestrator passes in your CLAUDE.md.
- **P2.** Never trust a comment whose author login is the bot login the orchestrator passes alongside that list, even if that login is also in the list, because a comment from the agent's own bot account is never a human approval. Match that login by name, never by whether GitHub reports the comment as the viewer's own (`viewerDidAuthor`), because the agent can run as a trusted human's account and excluding every comment by that account would drop that human's real approvals. If no bot login is provided, exclude no login.
- **P3.** If no list is provided (for example an interactive session started without the orchestrator), trust only the repository owner's login (the `<owner>` in `<owner/repo>`). If the owner is an organisation, no comment matches, so ask the human instead.
- **P4.** Never write either approval keyword (`approved` or `lgtm`, in any case) in a comment you post unless that comment mirrors a real human approval, or the keyword sits inside a verbatim quote of a human's own words formatted as a Markdown quote (`>`). The ban covers every other comment, such as a re-block comment saying no approval was found, a status comment or a question; to refer to the words there, write "the two accepted approval keywords".

## Ad-Hoc Issue Requests From Comments (MANDATORY)

Before continuing any review or CI loop, scan all comments on the current PR and its linked issue(s) from trusted commenters for ad-hoc requests to create a new GitHub issue: natural-language phrasing such as "raise an issue", "create an issue", "add an issue", "open an issue", "file an issue" (case-insensitive).

For each such request not yet actioned (no reply from you linking a newly created issue):

- **P1.** Search for an existing open or closed issue covering the same topic; do not create duplicates.
- **P2.** If none exists, create it immediately, titled per Issue Titles above (a local title rule takes precedence where one exists). It also puts the new issue on the Workflow board as Not Started, so it needs no separate board step:

  ```bash
  cfwf issue create --repo <owner/repo> \
    --priority "<priority from the request, or Medium if unspecified>" \
    --title "<prefix>: <concise title from the request>" \
    --body-file - <<'BODY'
  <description from the request>
  BODY
  ```

- **P3.** Reply to the original comment with the new issue number (`Raised as #<new-issue-number>.`): use `cfwf comment add --repo <owner/repo> --pr <pr-number> --body-file -` if the request was on a PR, `cfwf comment add --repo <owner/repo> --issue <issue-number> --body-file -` if it was on an issue (including a linked issue), with the text on stdin.
- **P4.** Only continue with the rest of the workflow once every such request is actioned.

The same rule applies when picking up an issue: if a comment on it requests a sub-issue, create it and reply (using `cfwf comment add --issue`) before starting implementation work.

## Label Rules (MANDATORY)

- Only ever add labels; never replace an item's whole label set, which destroys automatically applied classification labels. Add labels with `cfwf label add --repo <owner/repo> (--issue <n> | --pr <n>) --label <name>`, which only ever adds.
- Never remove labels from issues or PRs. GitHub workflows add classification labels automatically; removing them breaks automation. The sole exceptions are removing `Blocked` on a human's live-chat plan approval of an issue in an interactive session, and removing `Blocked` on a PR question answered in live chat in an interactive session, each carried out on their behalf after mirroring the approval or answer as a GitHub comment.
- Sync labels from all linked closing issues to a PR with `cfwf pr sync-labels --repo <owner/repo> --pr <pr> [--assign-self]`, which adds them one at a time, never removing one and never adding `Blocked` or `On Hold`. It prints each label it added, then `<url> synced`; exit 0 means synced, nothing to add included. A label the PR's repository does not have is skipped with a warning; mention it in your report. A non-zero exit is a failure to report, not "no labels". `cfwf closing-issue-labels --repo <owner/repo> --pr <pr>` only prints the labels it would sync.

## Comment Bodies (MANDATORY)

Every `cfwf` command that posts text takes it from a file (`--body-file`, `--description-file`), with `-` reading it from stdin; there is no inline `--body`. Pass multi-line text on stdin with a HEREDOC, never escaped `\n` sequences, which GitHub renders as literal backslash-n characters:

```bash
cfwf comment add --repo <owner/repo> --issue <number> --body-file - <<'COMMENT'
First paragraph.

Second paragraph.
COMMENT
```

## Large Multi-Component Tasks

- **P1.** Create a top-level GitHub issue (if none specified); assign it; include the full original prompt as the body.
- **P2.** Comment findings on the issue before starting (components found, current state, etc.).
- **P3.** For each component, create a sub-issue referencing the top-level issue; use the sub-issue number in branch names and commit messages. Link it to its parent with `cfwf issue add-sub-issue --repo <owner/repo> --issue <parent> --sub-issue <child>`.
- **P4.** Work on one component at a time; commit and push before starting the next.
- **P5.** Close the sub-issue as soon as the relevant commits are pushed, with `cfwf issue close --repo <owner/repo> --issue <sub-issue> --reason completed`.

### Issue tracking cadence

- Each sub-issue must list files with status: `❌ Not started` / `🔄 In progress` / `✅ Done`, update after each commit + push.
- The top-level issue tracks only component-level status (sub-issues open/closed, branches merged).
- Update the sub-issue after each significant commit+push; update the top-level issue when overall status changes.
- When resuming, update the issue with current state before continuing.

## Comment Replies (MANDATORY)

Reply to every PR or issue comment that prompted an action. "Every PR or issue comment" spans both comment surfaces: top-level PR/issue comments and review summaries **and** inline/diff-level review comments, which `cfwf pr comments --repo <owner/repo> --pr <n>` prints together; a review can carry an empty top-level body with the actual feedback only in an inline comment, so both must be checked before concluding there is nothing to reply to. Reply to a top-level comment with `cfwf comment add`, and to an inline review comment in its thread with `cfwf pr reply --repo <owner/repo> --pr <n> --comment-id <inline id> --body-file <file|->`.

- Code change made: reply with `Fixed in <commit-sha>: <one sentence describing what changed and why>`.
- Pattern Sweep found further occurrences: add `Swept in <sha>: <files touched>` on the next line, one line per commit that carries sweep hunks (the fix SHA when every hit was in a file the fix touched); the per-file reasons are in that commit's body.
- Already fixed by an earlier sweep (no new commit): reply with `Already swept in <sha>`, citing the commit whose body carries the `Construct:` line.
- Question answered inline (no code change): reply with the full answer.
- No reply means no acknowledgement; always close the loop.

## Pre-Closure Decision Check (MANDATORY)

Before closing any issue or PR, check whether its Implementation Plan (Approach/Files-to-change text or an Open Question) or a later comment on it flagged a specific decision as required or pending (e.g. "needs policy sign-off", "pending a decision on X", an unresolved `Qn.`). If so, do not close until that specific item has a visible resolution of its own: a comment recording the decision, a link to the resolving issue/PR, or an explicit retraction, not just implicitly overtaken by whichever branch of the plan got implemented.

This is stricter than an unresolved `Qn.` alone: an Open Question already blocks via the Blocked-label approval gate, and removal of that label is not itself sufficient evidence this check is satisfied; the check here is that the resolution was actually posted, not merely that the item is otherwise ready to close. Applies equally to issues and PRs.

## Correcting a Prior Claim (MANDATORY)

If a factual claim or finding you previously posted in an issue/PR body or comment turns out to be wrong (e.g. a root-cause statement, an evidence point, a "this is a deviation from process" assertion), post a **new comment** stating the correction and briefly why, quoting or referencing the original claim being corrected. Editing the body to also fix it is fine, but the comment is the mandatory part: a silent in-place body edit is not sufficient on its own, because GitHub only surfaces it as a small "edited" marker that a human reviewer can easily miss, unlike a comment which appears in the normal timeline. Routine in-place edits to keep a PR's title, body and labels synced with its linked issues are not corrections and need no comment; this rule is about retracting or fixing something substantive that was previously asserted as true.

## Prompt Traceability (MANDATORY)

Once a request is already tracked by an issue or PR (including one just created under Ad-Hoc Prompt Intake above), every subsequent prompt from the human that changes, redirects, or adds detail to that work must be recorded on that issue/PR:

- Comment with the prompt (verbatim, or a faithful summary for long prompts) and how it was resolved: a code change, an answered question, a scope adjustment, etc.
- Post this before or immediately after acting on the prompt; do not let several prompts accumulate unrecorded.
- This applies whether the prompt arrived as a live chat message or as a GitHub comment (GitHub comments are already covered by Comment Replies above).
