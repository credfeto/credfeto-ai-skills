---
name: credfeto-pr-sync
description: Keep pull request titles, bodies, and labels in sync with their linked issues, create PRs correctly when one does not yet exist, and manage PR lifecycle including bot-created PR ownership, draft state, environment/infrastructure block markers, and correcting prior claims. Use on every agent run that interacts with a PR, when creating or updating a PR, when checking for existing PRs before starting work, when replying to PR comments, when checking CI status on a PR, or when blocking a PR pending human input.
---

# Pull Request Sync and Lifecycle

## PR Creation (MANDATORY)

After pushing a commit that should be associated with a PR:

1. Wait up to 1 minute for GitHub to auto-create a PR: `gh pr list --head <branch> --repo <owner/repo>`. Create one if it is still absent (see GitHub CLI Proxy Behaviour below for the required flags when `GH_HOST` is set).
2. Title: Conventional Commits format matching the primary commit. For a placeholder-only commit that opens the PR before any real code exists, base the title on the issue title or expected Conventional Commits type instead, and correct it once the primary code commit lands if it differs.
3. Body: a summary of the change plus `Closes #<n>` for each linked issue (or `Related to #<n>` if it does not fully close the issue).
4. If the PR already exists, update the body rather than creating a duplicate.
5. Add yourself as assignee: `gh pr edit <number> --repo <owner/repo> --add-assignee @me`.
6. Leave the PR as draft; do not mark it ready or enable auto-merge as part of creation. That happens only after the full review process for the work item is satisfied.

## Title, Body, and Label Sync (MANDATORY: every PR interaction)

On every agent run, for every PR being interacted with:

1. Ensure the **title** accurately reflects all changes in the PR; update it if the scope has changed.
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

   The `Blocked` and `On-Hold` labels are explicitly excluded: workflow-control labels must never be synced from an issue to its PR.

4. Never remove any label from a PR or issue; GitHub workflows add labels automatically and they must not be removed.

## Correcting a Prior Claim (MANDATORY)

If a factual claim or finding previously posted in a PR body or comment turns out to be wrong (e.g. a root-cause statement, an evidence point, a "this is a deviation from process" assertion), post a **new comment** stating the correction and briefly why, quoting or referencing the original claim being corrected. Editing the body to also fix it is fine, but the comment is the mandatory part: a silent in-place body edit is not sufficient on its own, because GitHub only surfaces it as a small "edited" marker that a human reviewer can easily miss, unlike a comment which appears in the normal timeline.

This is distinct from the routine Title, Body, and Label Sync above, which requires ordinary in-place edits to keep a PR's title/body/labels synced with its linked issues; that is not a correction and needs no comment. This rule is about retracting or fixing something substantive that was previously asserted as true.

## Label Management (MANDATORY)

- Always use `--add-label` when adding labels; **never** `--label`, which replaces all existing labels and destroys automatically-applied classification labels.
- Never remove labels from issues or PRs.

## Comment Replies (MANDATORY)

Reply to every PR comment that prompted an action. Check both comment surfaces before concluding there is nothing to reply to: top-level PR comments and review summaries (`gh pr view <n> --repo <owner/repo> --json comments,reviews`) **and** inline/diff-level review comments (`gh api repos/<owner>/<repo>/pulls/<n>/comments`), since a review can carry an empty top-level body with the actual feedback only in an inline comment.

- Code change made: reply with `Fixed in <commit-sha>: <one sentence describing what changed and why>`.
- Question answered inline (no code change): reply with the full answer.
- No reply means no acknowledgement; always close the loop.

## Human Comment Requests: Run First (MANDATORY)

Before processing CI checks or continuing the review loop below, scan **all** comments on the current PR and its linked issue(s) from trusted commenters for ad-hoc requests to create a new GitHub issue: natural-language phrasing such as "raise an issue", "create an issue", "add an issue", "open an issue", "file an issue" (case-insensitive).

For each such request not yet actioned (no reply from you linking a newly created issue):

1. Search for an existing open or closed issue covering the same topic; do not create duplicates.
2. If none exists, create it immediately: `gh issue create --repo <owner/repo> --title "<concise title>" --body "<description>" --label "<priority label, or 'Medium' if unspecified>"`.
3. Reply to the original comment with the new issue number, using `gh pr comment` if the request was on the PR or `gh issue comment` if it was on a linked issue.
4. Only continue with CI Checks and the rest of the workflow once every such request is actioned.

## CI Checks (MANDATORY)

When working on a PR, check CI state once: `gh pr checks <number> --repo <owner/repo>`. Then act immediately; do not loop, sleep, or use `--watch`:

- All required checks passed → proceed with the next step.
- Any check pending or in_progress → stop silently; do not post a status comment. CI checks are bound by GitHub's own timeouts and will eventually pass, fail, or time out without intervention.
- Any check failed → investigate, fix, push, post a status comment, and stop. Do not wait for the new run to complete.
- CI consistently failing and cannot be fixed → mark the PR blocked: `gh pr edit <number> --repo <owner/repo> --add-label "Blocked"`.

## Blocked Label (MANDATORY)

When asking a question in a PR comment and waiting for an answer before continuing:

1. Add the `Blocked` label to the PR immediately after posting the question: `gh pr edit <number> --repo <owner/repo> --add-label "Blocked"`.
2. Do not continue working on the PR until the label is removed.
3. Use only the `Blocked` label for this purpose; never a substitute such as `do not merge` or `needs review`.
4. Live-chat approval is not sufficient on its own: if a human answers or approves in a live chat session rather than posting a GitHub comment directly, post the comment yourself, quoting the live instruction, before resuming work and before asking for `Blocked` to be removed.

## Environment/Infrastructure Block Marker (MANDATORY, PRs only)

When a Blocked-ing failure is diagnosed as an environment/infrastructure problem (a bug in the container image, a missing tool, a transient infra issue) rather than a bug in the PR's own code, add a machine-readable marker alongside the diagnosis so automation can auto-clear `Blocked` once the fix has actually shipped, instead of the PR sitting blocked until a human happens to notice:

1. Post the full human-readable diagnosis as normal: root cause, evidence, and (if known) the fix needed.
2. Append a single trailer line to that same comment:

   ```text
   <!-- orchestrator:env-block image-sha=${IMAGE_SHA_DEVELOPMENT_AGENT} -->
   ```

   Read `IMAGE_SHA_DEVELOPMENT_AGENT` from your own container environment; this records which image build was current when the diagnosis was made.
3. Apply the `Blocked` label exactly as in the section above.
4. Use this marker **only** for a genuine environment/infrastructure diagnosis. Automation auto-clears `Blocked` the moment it observes a differently-built agent image, with no further human involvement; marking a real code question or design decision this way would resume work before a human actually answered it.

This convention only applies to PRs. Everything else about the Blocked-label convention above is unchanged.

## PR Lifecycle

- Only one active branch or open PR per repository at a time; do not create another until the current one is merged and closed.
- **Before blocking new work** because of an existing PR: always verify its current state with `gh pr view <number> --repo <owner/repo> --json state,mergedAt`; never rely on conversation memory.
- When adding work to an open PR (review comments, missing coverage, CI fixes), convert to draft first: `gh pr ready <number> --undo`. Keep it in draft until testing and review are both satisfied; only convert it back when ready for submission.
- Assign yourself to PRs when creating or updating: `gh pr edit <number> --add-assignee @me`.

## Bot-Created PRs (MANDATORY: treat as your own)

GitHub is configured to automatically create PRs from pushed branches. These PRs appear authored by `app/github-actions` but the commits are authored by you.

Before starting any work in a repository:

1. Run `gh pr list --state open --repo <owner/repo> --json number,title,author,headRefName,url`, no `--author @me` filter.
2. For any PR authored by `app/github-actions`, check the commit authors: `gh pr view <n> --repo <owner/repo> --json commits --jq '.commits[].authors[].login'`.
3. If **all commits** are from your account, **take ownership**: update the PR title and body to match the proper format (summary, `Closes #<n>`, test plan), add yourself as assignee, and treat it as your active PR for that repo.
4. If commits are from multiple authors (e.g. you plus a human or Copilot), do **not** take over; leave the PR as-is.
5. Do **not** create a new branch or PR for the same issue; that would be duplicate work.

**Checking for existing work before branching (MANDATORY):**

- Check branch names in all open PRs, not just PR authors. If any open PR's `headRefName` contains the issue number, that is your work from a prior session; resume it instead of creating a new branch.

When you find a duplicate pair (a bot-created PR and one you authored yourself, for the same issue or branch):

- Keep whichever has the more complete body and later review activity.
- Close the other with a comment explaining which PR supersedes it.

## GitHub CLI Comment Bodies (MANDATORY)

When posting comment or PR bodies via the GitHub CLI, always pass multi-line text using a HEREDOC so that real newline characters are embedded. **Never** use escaped `\n` sequences; GitHub renders them as literal characters:

```bash
gh pr comment <number> --repo <owner/repo> --body "$(cat <<'COMMENT'
First paragraph.

Second paragraph.
COMMENT
)"
```

## GitHub CLI Proxy Behaviour

When `GH_HOST` is set to a value other than `github.com`, `gh` routes through a proxy:

- **`gh pr create`:** always pass both `--repo <owner>/<repo>` and `--head <owner>:<branch>`. Without `--repo`, `gh` performs a client-side check that a git remote URL's hostname matches `GH_HOST`: since remotes use `github.com` but `GH_HOST` is the proxy host, no remote matches and `gh` refuses before any API request reaches the proxy. Without `--head`, `gh` may try to detect the branch from git remotes, leading to a blank head ref at the proxy's GraphQL layer.

  ```bash
  gh pr create \
    --repo <owner>/<repo> \
    --head <owner>:<branch-name> \
    --base main \
    --draft \
    --title "..." \
    --body "..."
  ```

- If a `gh` command fails, raise an issue on `credfeto/github-api-proxy` with the exact subcommand and flags, the API method (if visible), and the full error message.
- Commit and push operations are always rejected by the proxy; use the `git` CLI directly for all commit and push operations.
