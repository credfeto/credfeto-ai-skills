---
name: credfeto-github-issue
description: Create and manage GitHub issues correctly — duplicate search, planned descriptions, priority/status labels, assignment, and the Blocked label rules for AI-initiated issues, including the mandatory tracking issue required before starting any ad-hoc task. Use when asked to create a GitHub issue, when raising an issue autonomously, when a human asks you to do something and no existing issue or PR is already specified, when a PR or issue comment asks you to raise an issue, when selecting the next issue to work on, or when asking a blocking question and needing to mark an item Blocked.
---

# GitHub Issue Management

Use `gh` to manage issues for every piece of work. Only update issues if `gh` is installed and authenticated (`gh auth status`); otherwise read code and git log for state.

## Before Starting Work

- Either find a **100% matching** existing issue (confirm with the user before linking) or create a new one with the original prompt and a clear description.
- Assign yourself before starting: `gh issue edit <number> --add-assignee @me`.
- Only work on unassigned issues or issues already assigned to you.
- Skip any issue labelled `On-Hold` or `Blocked`.
- Reference issue numbers in commit messages and branch names.
- If work on an issue is abandoned, comment with findings before closing — do not abandon silently.

## Issue Creation Flow (MANDATORY when asked to create or update an issue)

When the issue itself is the requested deliverable:

1. Enter Plan Mode.
2. Work out at a high level what code change the issue would represent — scope, affected files, approach.
3. Exit Plan Mode and return to auto.
4. Create the issue, or update the existing issue, using the plan output to write a meaningful description.

This is distinct from Ad-Hoc Prompt Intake below, which covers being asked to _do_ something — there, the issue is a tracking side-effect rather than the deliverable itself.

## Ad-Hoc Prompt Intake (MANDATORY)

Applies whenever a human asks you to _do_ something in the context of a repo (a task — not a request to raise an issue) and no existing issue or PR has already been specified as the thing to work on. No exception for how trivial the request seems.

1. Before taking any other action (including answering a read-only question), create a GitHub issue in the current repo:
   - Title: a concise summary of the prompt.
   - Body: the prompt, verbatim, as the starting point.
   - Labels: `AI-Work` and `Blocked` (minimum) — always, regardless of who initiated the underlying task; add other relevant labels (e.g. priority) as appropriate.
2. Work out scope, affected files, and approach, and post it as an issue comment before starting, using exactly this format:

   ```text
   ## Implementation Plan

   ### Files to change
   - `path/to/file` — reason

   ### Approach
   <one-paragraph description>

   ### Test strategy
   <what will be tested and how>

   ### Assumptions
   <list or "None">

   ### Open questions
   <list or "None — ready to proceed pending approval">
   ```

3. As open questions are identified, add each as an issue comment as soon as it's identified — do not batch them all until the end.
4. Do not proceed until an explicit human approval comment exists (`approved` / `go ahead` / `looks good` / `lgtm`) and `Blocked` is removed — if approval came via live chat, mirror it as a GitHub comment first.
5. Once approved and `Blocked` is removed:
   - If the request needs a code change, proceed and open a PR referencing the issue when ready.
   - If the request is read-only/informational (no code change), post the answer as an issue comment and close the issue.

## AI-Initiated Issues (MANDATORY)

When raising a GitHub issue autonomously (not directly requested by a human):

1. Search for existing issues (both **open** and **closed**) covering the same topic before creating — do not create duplicates.
2. Add the `Blocked` label immediately after creating the issue so it is held for human review before being acted upon.

Exceptions — do not add `Blocked`:

- A human explicitly asked you to raise the issue: ask for the priority label instead, then apply it.
- The issue is raised by the dependency security detection rule (e.g. flagged during `npm install` or from a Dependabot advisory): use only the labels specified by that rule — see [Dependency Security Issues](#dependency-security-issues) below.

## Dependency Security Issues

After any push, if the remote reports vulnerabilities:

- Check for open Dependabot PRs covering them (`gh pr list --label dependencies`).
- If none exist, visit the repo's Dependabot page and for any manually fixable advisory create a GitHub issue labelled `Security` and `AI-Work`, naming the package, severity, and fix steps.

## Priority Labels (highest to lowest)

| Label | Meaning |
| --- | --- |
| `Security` | Security fix — highest possible priority |
| `Urgent` | Get this done ASAP; security fixes take precedence |
| `High` | Addressed after `Urgent` work |
| `Medium` | Addressed after `High` work |
| `Low` | Addressed after `Medium` work |
| _(untagged)_ | No priority set — tracked but timing does not matter |

When selecting the next issue to work on, prefer issues with higher-priority labels.

## Status Labels

| Label | Meaning |
| --- | --- |
| `On-Hold` | Needs further thought or cannot be implemented yet — do not start work |
| `Blocked` | Needs human input before work can continue |

## Blocked Label (MANDATORY)

When asking a question in an issue or PR comment and waiting for an answer before continuing:

1. Add the `Blocked` label immediately after posting the question:
   - Issue: `gh issue edit <number> --repo <owner/repo> --add-label "Blocked"`
   - PR: `gh pr edit <number> --repo <owner/repo> --add-label "Blocked"`
2. Do not continue working on the item until the label is removed.
3. Use only the `Blocked` label for this purpose — never a substitute such as `do not merge` or `needs review`.
4. Live-chat approval is not sufficient on its own: if a human answers or approves in a live chat session rather than posting a GitHub comment directly, post the comment yourself — quoting the live instruction — before resuming work and before asking for `Blocked` to be removed. The record must survive even if the chat session is lost.

## Ad-Hoc Issue Requests From Comments (MANDATORY)

Before continuing any review or CI loop, scan all comments on the current PR and its linked issue(s) from trusted commenters for ad-hoc requests to create a new GitHub issue — natural-language phrasing such as "raise an issue", "create an issue", "add an issue", "open an issue", "file an issue" (case-insensitive).

For each such request not yet actioned (no reply from you linking a newly created issue):

1. Search for an existing open or closed issue covering the same topic — do not create duplicates.
2. If none exists, create it immediately:

   ```bash
   gh issue create --repo <owner/repo> \
     --title "<concise title from the request>" \
     --body "<description from the request>" \
     --label "<priority label from the request, or 'Medium' if unspecified>"
   ```

3. Reply to the original comment with the new issue number: use `gh pr comment` if the request was on a PR, `gh issue comment` if it was on an issue.
4. Only continue with the rest of the workflow once every such request is actioned.

The same rule applies when picking up an issue: if a comment on it requests a sub-issue, create it and reply before starting implementation work.

## Label Rules (MANDATORY)

- Always use `--add-label` — **never** `--label`, which replaces all existing labels.
- Never remove labels from issues or PRs — GitHub workflows add classification labels automatically.

## Comment Bodies (MANDATORY)

Always pass multi-line text using a HEREDOC — never escaped `\n` sequences:

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
4. Work on one component at a time — commit and push before starting the next.
5. Close the sub-issue as soon as the relevant commits are pushed.

### Issue tracking cadence

- Each sub-issue must list files with status: `❌ Not started` / `🔄 In progress` / `✅ Done` — update after each commit + push.
- The top-level issue tracks only component-level status (sub-issues open/closed, branches merged).
- When resuming, update the issue with current state before continuing.
