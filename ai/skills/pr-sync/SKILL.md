---
name: credfeto-pr-sync
description: Keep pull request titles, bodies, and labels in sync with their linked issues, and manage PR lifecycle including bot-created PR ownership and draft state. Use on every agent run that interacts with a PR, when creating or updating a PR, or when checking for existing PRs before starting work.
---

# Pull Request Sync and Lifecycle

## Title, Body, and Label Sync (MANDATORY — every PR interaction)

On every agent run, for every PR being interacted with:

1. Ensure the **title** accurately reflects all changes in the PR — update it if the scope has changed.
2. Ensure the **body** summarises all changes and includes `Closes #<n>` for each linked issue, if any.
3. Sync labels from all linked closing issues to the PR:

   ```bash
   gh pr view <pr> --repo <owner/repo> --json closingIssuesReferences \
     --jq '.closingIssuesReferences[].number' \
   | while IFS= read -r n; do
       gh issue view "$n" --repo <owner/repo> --json labels --jq '.labels[].name' \
         || echo "Warning: could not fetch labels for issue $n" >&2
     done \
   | sort -u \
   | grep -vE '^(Blocked|On-Hold)$' \
   | while IFS= read -r label; do
       gh pr edit <pr> --repo <owner/repo> --add-label "$label" \
         || echo "Warning: could not add label '$label' to PR" >&2
     done
   ```

   The `Blocked` and `On-Hold` labels are explicitly excluded — workflow-control labels must never be synced from an issue to its PR.

4. Never remove any label from a PR or issue — GitHub workflows add labels automatically and they must not be removed.

## Label Management (MANDATORY)

- Always use `--add-label` when adding labels — **never** `--label`, which replaces all existing labels and destroys automatically-applied classification labels.
- Never remove labels from issues or PRs.

## PR Lifecycle

- Only one active branch or open PR per repository at a time; do not create another until the current one is merged and closed.
- **Before blocking new work** because of an existing PR: always verify its current state with `gh pr view <number> --repo <owner/repo> --json state,mergedAt` — never rely on conversation memory.
- When adding work to an open PR (review comments, missing coverage, CI fixes), convert to draft first: `gh pr ready <number> --undo`. Keep it in draft until testing and review are both satisfied — only convert it back when ready for submission.
- Assign yourself to PRs when creating or updating: `gh pr edit <number> --add-assignee @me`.

## Bot-Created PRs (MANDATORY — treat as your own)

GitHub is configured to automatically create PRs from pushed branches. These PRs appear authored by `app/github-actions` but the commits are authored by you.

Before starting any work in a repository:

1. Run `gh pr list --state open --repo <owner/repo> --json number,title,author,headRefName,url` — no `--author @me` filter.
2. For any PR authored by `app/github-actions`, check the commit authors: `gh pr view <n> --repo <owner/repo> --json commits --jq '.commits[].authors[].login'`.
3. If **all commits** are from your account, **take ownership**: update the PR title and body to match the proper format (summary, `Closes #<n>`, test plan), add yourself as assignee, and treat it as your active PR for that repo.
4. If commits are from multiple authors (e.g. you plus a human or Copilot), do **not** take over — leave the PR as-is.
5. Do **not** create a new branch or PR for the same issue — that would be duplicate work.

When you find a duplicate pair (a bot-created PR and one you authored yourself, for the same issue or branch):

- Keep whichever has the more complete body and later review activity.
- Close the other with a comment explaining which PR supersedes it.

## GitHub CLI Comment Bodies (MANDATORY)

When posting comment or PR bodies via the GitHub CLI, always pass multi-line text using a HEREDOC so that real newline characters are embedded. **Never** use escaped `\n` sequences — GitHub renders them as literal characters:

```bash
gh pr comment <number> --repo <owner/repo> --body "$(cat <<'COMMENT'
First paragraph.

Second paragraph.
COMMENT
)"
```

## GitHub CLI Proxy Behaviour

When `GH_HOST` is set to a value other than `github.com`, `gh` routes through a proxy:

- If a `gh` command fails, raise an issue on `credfeto/github-api-proxy` with the exact subcommand and flags, the API method (if visible), and the full error message.
- Commit and push operations are always rejected by the proxy — use the `git` CLI directly for all commit and push operations.
