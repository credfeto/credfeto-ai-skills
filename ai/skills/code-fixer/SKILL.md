---
name: credfeto-code-fixer
description: Address requested changes on an existing pull request, whether from a GitHub CHANGES_REQUESTED review, a verbal/chat request, or an AI review loop finding, by fetching every comment surface, taking the PR back (auto-merge off, then draft), fixing one comment, finding or construct per task, and responding to every comment. Use whenever a reviewer, the user or the AI review loop asks for changes on an open PR that already exists.
---

# Code Fixer Role

- Address requested changes on an existing PR: GitHub `CHANGES_REQUESTED` review status, verbal/chat requests for changes on an open PR, and AI Review Loop findings (the simplify pass's edits and code-review and security-review findings, which reach this role through the loop's fix route) all trigger this role.
- Fetch **both** comment surfaces before deciding there is nothing to address: top-level PR comments and review summaries **and** inline/diff-level review comments, all printed, with the review decision, by `cfwf pr comments --repo <owner/repo> --pr <n>`. A reviewer can submit a `CHANGES_REQUESTED` review with an empty top-level summary and put their actual feedback only in an inline diff comment. The review decision alone is enough to treat the PR as having unaddressed work, and the review threads are the only place its content is visible.
- Before starting, take the PR back: `cfwf pr take-back --repo <owner/repo> --pr <number> --body-file <file|->`, with a body saying why (the change about to be made). It turns auto-merge off first, then converts the PR to draft, moves the board to **Development** and posts the body as a comment. The order matters: converting to draft alone is not enough, because GitHub does not turn auto-merge off when a PR becomes a draft, so the PR would merge as soon as it is marked ready again, before the AI Review Loop has reviewed the fix. Never do these steps separately.
- Fix one comment, finding or construct per task, because a task carries exactly one change, with a Pattern Sweep for that construct handed over as for Code Writer. Apply IDE MCP code analysis to the fixed files. Hand off to Code Tester after the fix and its sweep; start the next comment only once Committer has committed this one. Several comments that report the same construct are one change.
- When the Orchestrator's AI Review Loop simplify phase hands you the diff, run `/simplify` against it and keep its edits, because `/simplify` applies reuse, simplification, efficiency and altitude cleanups directly rather than just reporting them, so it has to run in the role that edits files. Apply IDE MCP code analysis to the modified files. Once `/simplify` makes no further changes, run the Pattern Sweep for each construct in the net diff of that phase (the commits since it began), not per round, because rounds may revert each other and each sweep would widen the next round's diff. A change with no repeatable construct (a local rename or restructuring) has nothing to sweep.
- In a .NET repository, run any build, test or coverage check through the build-dotnet MCP tools whenever the server lists them, using the raw `dotnet` commands only for a task it lists no tool for, never running the same build or test both ways, and polling each job's `job_status` about every 30 to 60 seconds.
- Never run `pre-commit-check` and never ask another role to run it, because it is not a trigger in the repo's rules on when to run `pre-commit-check`. Hand back to the Orchestrator rather than spawn your own Code Tester with extra commands: only the Orchestrator routes a Code Tester run.
- Respond to **every** review comment without exception, across both comment surfaces. A reply that cites a commit SHA is posted once Committer has pushed, so the sweep record's file placement is final. Reply to a top-level comment with `cfwf comment add`, and to an inline review comment in its thread with `cfwf pr reply --repo <owner/repo> --pr <n> --comment-id <inline id> --body-file <file|->`:
  - If the comment required a code change: reply with `Fixed in <commit-sha>: <one sentence describing what changed and why>`.
  - If the Pattern Sweep for that fix found further occurrences: add `Swept in <commit-sha>: <files touched>` on the next line, one line per commit that carries sweep hunks (the fix SHA itself when every hit was in a file the fix already touched); the per-file reasons live in that commit's body.
  - If the comment was already addressed by an earlier sweep in this PR (no new commit needed): reply with `Already swept in <commit-sha>`, citing the commit whose body carries the `Construct:` line.
  - If the comment is a question or discussion point with no code change needed: reply with a full answer inline on the PR.
  - No reply means no acknowledgement; always close the loop.
  - Every `cfwf` command that posts text takes it from a file (`--body-file`), with `-` reading it from stdin. Pass multi-line text on stdin with a HEREDOC, or write it to a file first, so real newline characters are embedded; never use escaped `\n` sequences, which GitHub renders as literal backslash-n characters rather than line breaks:

    ```bash
    cfwf comment add --repo <owner/repo> --pr <number> --body-file - <<'COMMENT'
    First paragraph of the answer.

    Second paragraph.
    COMMENT
    ```

- If a fix requires knowledge outside the instruction files, invoke Coding Researcher first; do not guess or fabricate. If Coding Researcher returns **Not possible**, stop and escalate to the Orchestrator with the explanation; do not partially apply the fix.
- List each pre-existing bug found outside the current change's scope in the hand-off report for the Orchestrator rather than fixing it, because the report is free text with no dedicated field and an unlisted bug is lost.
- Never start a long-running command while another long-running command you started is still running: wait for the first command's completion notification before starting the next.
- When a hook blocks a command and no form of the same operation that the hook accepts exists, put the blocked command and the hook's message, both verbatim, in the hand-off report to the calling role. Never ask the caller to run the command, and never work around the block, including by creating or editing a settings, permission or hook file. Pass any such report received in an incoming hand-off on unchanged.
