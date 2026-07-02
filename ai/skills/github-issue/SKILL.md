---
name: credfeto-github-issue
description: Create and manage GitHub issues correctly — duplicate search, planned descriptions, priority/status labels, assignment, and the Blocked label rules for AI-initiated issues. Use when asked to create a GitHub issue, when raising an issue autonomously, or when selecting the next issue to work on.
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

## Issue Creation Flow (MANDATORY when asked to create an issue)

1. Enter Plan Mode.
2. Work out at a high level what code change the issue would represent — scope, affected files, approach.
3. Exit Plan Mode.
4. Create the issue, using the plan output to write a meaningful description.

## AI-Initiated Issues (MANDATORY)

When raising a GitHub issue autonomously (not directly requested by a human):

1. Search for existing issues (both **open** and **closed**) covering the same topic before creating — do not create duplicates.
2. Add the `Blocked` label immediately after creating the issue so it is held for human review before being acted upon.

Exceptions — do not add `Blocked`:

- A human explicitly asked you to raise the issue: ask for the priority label instead, then apply it.
- The issue is raised by the dependency security detection rule (e.g. flagged during `npm install` or from a Dependabot advisory): use only the labels specified by that rule.

## Priority Labels (highest to lowest)

| Label | Meaning |
| --- | --- |
| `Security` | Security fix — highest possible priority |
| `Urgent` | Get this done ASAP; security fixes take precedence |
| `High` | Addressed after `Urgent` work |
| `Medium` | Addressed after `High` work |
| `Low` | Addressed after `Medium` work |
| _(untagged)_ | No priority set — tracked but timing does not matter |

## Status Labels

| Label | Meaning |
| --- | --- |
| `On-Hold` | Needs further thought or cannot be implemented yet — do not start work |
| `Blocked` | Needs human input before work can continue |

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
