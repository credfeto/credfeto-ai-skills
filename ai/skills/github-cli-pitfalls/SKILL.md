---
name: credfeto-github-cli-pitfalls
description: Reference of specific `gh` and `gh api`/GraphQL failure modes that have each actually broken a live session, with the exact fix for each. Use before composing an uncertain `gh`/`gh api` command, when a `gh`, `gh api`, or GraphQL call fails with an unexpected flag/field/type error, a `422 Validation Failed`, a `jq` parse error immediately after a `gh` call, or a shell command is rejected by the agent sandbox.
---

# GitHub CLI Pitfalls

Each of these has actually broken a live session; check here before assuming a flag or field
exists, or before guessing at why a `gh`/`gh api` call failed.

## `--assignee`/`--label` Are Create-Only Flags

`gh issue create`/`gh pr create` accept `--assignee`/`--label`. `gh issue edit`/`gh pr edit` do
**not**; they fail with `unknown flag: --assignee` / `unknown flag: --label`. Use
`--add-assignee`/`--add-label` (and `--remove-assignee`/`--remove-label`) on `edit`. There is also
no `gh issue assign` subcommand: `gh issue assign <n> --assignee @me` fails; use
`gh issue edit <n> --add-assignee @me`.

`--label` on `edit` also has a second failure mode even where it *would* be accepted: it
**replaces** the entire label set rather than adding to it. Always use `--add-label`:

```bash
gh pr edit <number> --repo <owner>/<repo> --add-label "Security" --add-label "Urgent"
```

## `--json` Only Accepts the Fixed Field List for That Subcommand

Each `gh ... view`/`gh ... list` subcommand has its own fixed set of valid `--json` field names;
passing a field outside that set fails immediately, for example `timelineItems` is not a valid
field on `gh issue view` and fails with `Unknown JSON field: "timelineItems"`. To find the PR(s)
that closed an issue, use `closedByPullRequestsReferences` on the issue, or
`closingIssuesReferences` on the PR; do not reach for GraphQL timeline scraping first. When a
field name is uncertain, run `gh <command> --help` rather than guessing from memory or from a
similar-looking command.

## Never Merge stderr Into a Pipe Feeding `jq`

`gh ... 2>&1 | jq ...` puts any warning `gh` writes to stderr into the same stream as the JSON
body, corrupting it before `jq` sees valid input, even on an otherwise-successful call. This
produces errors like `jq: parse error: Invalid numeric literal ...` that look like a `jq` or data
problem but are actually the merged stderr. Let stderr go to the terminal (`gh ... | jq ...`) or
redirect it to a file if it needs inspecting separately (`gh ... 2>err.log | jq ...`).

## Inline PR Review Comments: Stale `commit_id` or Out-of-Diff `path`/`line`

`gh api repos/<owner>/<repo>/pulls/<n>/comments` fails with
`422 Validation Failed: pull_request_review_thread.path could not be resolved` if `commit_id` is
stale or `path`/`line` don't fall inside that commit's actual diff. Fetch the PR's current head SHA
and the actual changed files first rather than guessing:

```bash
gh pr view <n> --repo <owner>/<repo> --json headRefOid --jq '.headRefOid'
gh api repos/<owner>/<repo>/pulls/<n>/files --jq '.[].filename'
```

`commit_id` must be that current head SHA, and `path`/`line` must be inside that commit's diff.

To reply to an existing review comment thread, use `-F` (typed), not `-f`, for `in_reply_to`: the
API requires it as a number, and `-f` sends it as a string, failing with
`"in_reply_to" is not a permitted key" / "is not a number"`:

```bash
gh api repos/<owner>/<repo>/pulls/<number>/comments \
  -X POST \
  -f body="<reply text>" \
  -F in_reply_to=<comment-id>
```

## GraphQL `ProjectV2` Collaborator Mutations

The input type is `ProjectV2Collaborator`, not the plausible-looking `ProjectV2CollaboratorInput`
(the latter errors with `isn't a defined input type`). Any connection field selected in a
mutation's return payload (e.g. `collaborators { nodes { ... } }`) needs an explicit `first`/`last`
pagination argument, or the whole mutation is rejected with `MISSING_PAGINATION_BOUNDARIES`, even
though the mutation itself already took effect.

## `gh api -f`/`-F` Are Not Interchangeable

`-f`/`--raw-field` always sends a string; `-F`/`--field` sends a typed value (numbers, booleans,
`@file`). A field the API schema declares as a number (e.g. `in_reply_to` when replying to a PR
review comment, see above) must use `-F`. Using `-f` for it fails with
`"in_reply_to" is not a permitted key" / "is not a number"`, because the string form doesn't match
any of the schema's `oneOf` variants.

## The Agent Sandbox Rejects Some Shell Shapes Outright

`IFS=` assignments (e.g. a `while IFS= read -r` loop) and `env`/`unset` wrappers are rejected
outright by the sandbox, regardless of what the underlying `gh` command would have done. Use flat
commands, and pass lists in one call (e.g. `--add-label "a,b"`) instead of looping.

## Comment and Body Text: HEREDOC, Never `\n`

When posting any `--body` (or `-f body=`) that contains, or may contain, newlines (`gh issue
comment`, `gh pr comment`, `gh issue create`, `gh pr create`, `gh issue edit`, `gh pr edit`,
`gh api ... -f body=`, etc.), always build it with a HEREDOC so real newline characters are
embedded. **Never** use escaped `\n` sequences; GitHub renders them as literal backslash-n
characters, not line breaks:

```bash
gh issue comment <number> --repo <owner>/<repo> --body "$(cat <<'COMMENT'
First paragraph.

Second paragraph.
COMMENT
)"
```
