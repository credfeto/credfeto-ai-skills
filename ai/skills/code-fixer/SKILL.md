---
name: credfeto-code-fixer
description: Address requested changes on an existing pull request, whether from a GitHub CHANGES_REQUESTED review or a verbal/chat request, by fetching every comment surface, converting the PR to draft, and responding to each comment with its own commit. Use whenever a reviewer or the user asks for changes on an open PR that already exists.
---

# Code Fixer Role

- Address requested changes on an existing PR: both GitHub `CHANGES_REQUESTED` review status and verbal/chat requests for changes on an open PR trigger this role.
- Fetch **both** comment surfaces before deciding there is nothing to address:
  - Top-level PR comments and review summaries: `gh pr view <n> --repo <owner/repo> --json comments,reviews,reviewDecision`
  - Inline/diff-level review comments: `gh api repos/<owner>/<repo>/pulls/<n>/comments`
  - A reviewer can submit a `CHANGES_REQUESTED` review with an empty top-level summary and put their actual feedback only in an inline diff comment. The review decision alone is enough to treat the PR as having unaddressed work, and the inline-comment endpoint is the only place its content is visible.
- Convert the PR to draft before starting: `gh pr ready <number> --repo <owner/repo> --undo`.
- One commit per review comment. Hand off to the test/build verification role after each fix.
- Respond to **every** review comment without exception:
  - If the comment required a code change: reply with `Fixed in <commit-sha>: <one sentence describing what changed and why>`.
  - If the comment is a question or discussion point with no code change needed: reply with a full answer inline on the PR.
  - To reply to an inline/diff-level review comment so it threads correctly (rather than posting a disconnected top-level comment), use `-F` (typed), not `-f`, for `in_reply_to`: the API requires it as a number, and `-f` sends it as a string, failing with `"in_reply_to" is not a permitted key"` / `is not a number`:
    ```bash
    gh api repos/<owner>/<repo>/pulls/<n>/comments \
      -X POST \
      -f body="<reply text>" \
      -F in_reply_to=<comment-id>
    ```
- If a fix requires knowledge outside the instruction files (unfamiliar API, complex library usage), research it first rather than guessing or fabricating a fix.
  - If research determines the fix is **not possible** as scoped, stop and escalate with the explanation; do not partially apply a guess.
