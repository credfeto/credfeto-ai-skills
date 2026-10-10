---
name: credfeto-code-fixer
description: Address requested changes on an existing pull request, whether from a GitHub CHANGES_REQUESTED review, a verbal/chat request, or an AI review loop finding, by fetching every comment surface, turning auto-merge off and converting the PR to draft, fixing one comment, finding or construct per task, and responding to every comment. Use whenever a reviewer, the user or the AI review loop asks for changes on an open PR that already exists.
---

# Code Fixer Role

- Address requested changes on an existing PR: GitHub `CHANGES_REQUESTED` review status, verbal/chat requests for changes on an open PR, and AI Review Loop findings (the simplify pass's edits and code-review and security-review findings, which reach this role through the loop's fix route) all trigger this role.
- Fetch **both** comment surfaces before deciding there is nothing to address:
  - Top-level PR comments and review summaries: `gh pr view <n> --repo <owner/repo> --json comments,reviews,reviewDecision`
  - Inline/diff-level review comments: `gh api repos/<owner>/<repo>/pulls/<n>/comments`
  - A reviewer can submit a `CHANGES_REQUESTED` review with an empty top-level summary and put their actual feedback only in an inline diff comment. The review decision alone is enough to treat the PR as having unaddressed work, and the inline-comment endpoint is the only place its content is visible.
- Before starting, turn auto-merge off, then convert the PR to draft (`gh pr ready <number> --repo <owner/repo> --undo`). Converting to draft alone is not enough, because GitHub does not turn auto-merge off when a PR becomes a draft, so the PR would merge as soon as it is marked ready again, before the AI Review Loop has reviewed the fix. Turn auto-merge off with `gh pr merge <number> --repo <owner/repo> --disable-auto` only when `gh pr view <number> --repo <owner/repo> --json autoMergeRequest --jq '.autoMergeRequest'` prints something other than `null`, because GitHub does not document what `--disable-auto` does on a PR with no auto-merge request.
- Fix one comment, finding or construct per task, because a task carries exactly one change, with a Pattern Sweep for that construct handed over as for Code Writer. Apply IDE MCP code analysis to the fixed files (see the ide-mcp-code-analysis skill for the full best-effort and reporting procedure). Hand off to Code Tester after the fix and its sweep; start the next comment only once Committer has committed this one. Several comments that report the same construct are one change.
- Respond to **every** review comment without exception, across both comment surfaces. A reply that cites a commit SHA is posted once Committer has pushed, so the sweep record's file placement is final:
  - If the comment required a code change: reply with `Fixed in <commit-sha>: <one sentence describing what changed and why>`.
  - If the Pattern Sweep for that fix found further occurrences: add `Swept in <commit-sha>: <files touched>` on the next line, one line per commit that carries sweep hunks (the fix SHA itself when every hit was in a file the fix already touched); the per-file reasons live in that commit's body.
  - If the comment was already addressed by an earlier sweep in this PR (no new commit needed): reply with `Already swept in <commit-sha>`, citing the commit whose body carries the `Construct:` line.
  - If the comment is a question or discussion point with no code change needed: reply with a full answer inline on the PR.
  - No reply means no acknowledgement; always close the loop.
  - To reply to an inline/diff-level review comment, use `-F` (typed), not `-f`, for `in_reply_to`: the API requires it as a number, and `-f` sends it as a string, failing with `"in_reply_to" is not a permitted key"` / `is not a number`:

    ```bash
    gh api repos/<owner>/<repo>/pulls/<n>/comments \
      -X POST \
      -f body="<reply text>" \
      -F in_reply_to=<comment-id>
    ```

  - Whenever a reply body contains, or may contain, newlines (a multi-paragraph answer to a discussion point), build it with a HEREDOC so real newline characters are embedded; never use escaped `\n` sequences, which GitHub renders as literal backslash-n characters rather than line breaks:

    ```bash
    gh pr comment <number> --repo <owner>/<repo> --body "$(cat <<'COMMENT'
    First paragraph of the answer.

    Second paragraph.
    COMMENT
    )"
    ```

- If a fix requires knowledge outside the instruction files, invoke Coding Researcher first; do not guess or fabricate. If Coding Researcher returns **Not possible**, stop and escalate to the Orchestrator with the explanation; do not partially apply the fix.
- List each pre-existing bug found outside the current change's scope in the hand-off report for the Orchestrator rather than fixing it, because the report is free text with no dedicated field and an unlisted bug is lost.
