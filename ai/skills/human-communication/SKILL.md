---
name: credfeto-human-communication
description: Raise anything that needs the human (a question, decision, approval or manual step) in a NEEDS YOU block at the top of the reply, ask in chat first in an interactive session before posting on the issue or PR and adding `Blocked`, and give the full URL of every GitHub issue, pull request, comment, workflow run or commit named to the human. Use whenever replying to the human, relaying a sub-agent's report, writing a final report, or when something needs a human answer.
---

# Human Communication

Covers how to raise anything that needs the human, so it is never buried in a routine status update, and how to name GitHub items to the human so each one can be opened directly.

## NEEDS YOU Block (MANDATORY)

In an interactive session, a question, decision, approval or manual step that needs the human is easy to miss in the middle or at the end of a status update, and the work then waits on an answer nobody knows has been asked. Raise it so it cannot be missed:

- **P1.** Raise anything that needs the human (a question, a decision, an approval or a manual step) as soon as it is identified, not at the end of the current batch of work.
- **P2.** Put it at the **top** of the reply, in a highlighted block whose first line is a marker for how urgent it is, followed by one bullet per item:

  ```markdown
  > 🛑 **NEEDS YOU:**
  > - **Q12.** <yes/no question>
  ```

- **P3.** Use exactly one of these markers, keeping the emoji and the bold label together on the line so the status still reads correctly without colour. Write each marker as the emoji character, never a GitHub shortcode, because a terminal shows a shortcode as plain text, while the character displays the same in a terminal and on GitHub:
  - `🛑 **NEEDS YOU:**`: the work is stopped until the human answers.
  - `⚠️ **NEEDS YOU:**`: a question is open, but the agent can carry on with other work in the meantime.
  - `✅ **NEEDS YOU:** nothing right now.`: nothing is outstanding.
- **P4.** Keep the block at the top of every reply while anything is still outstanding, so it never scrolls out of view. Once nothing is outstanding, either show `> ✅ **NEEDS YOU:** nothing right now.` or leave the block out.
- **P5.** Number questions in the block with a `Q` prefix, continuing from the highest number already used in the work item (its issue and PR) and never reusing a number. Phrase each as a yes/no question where possible, so it can be answered in one word.
- **P6.** Before asking, gather what a command can show; ask only for what no command can show.
- **P7.** Only the main session talks to the human. A role working from a hand-off puts anything that needs the human in its hand-off report, and the main session raises it in the block.

## Ask in Chat First (MANDATORY)

- **P1.** In an interactive session, ask the question in chat, in the NEEDS YOU block, rather than posting it on the issue or PR and adding `Blocked`, because the human is present and answers within minutes, and a `Blocked` label they have already answered is noise someone then has to clear.
- **P2.** Post the question on the issue or PR and add `Blocked`, with `cfwf issue block` or `cfwf pr block`, only when it is still unanswered when the session would otherwise stop, so the question survives the session.
- **P3.** An answer given in chat is still recorded on GitHub: mirror it as a comment, and record the prompt and its outcome, so the record survives even if the chat session is lost.
- **P4.** An unattended run is unchanged: post the question on the issue or PR and add `Blocked` straight away, because no human is watching the chat.
- **P5.** Plan approval is unchanged: the plan is still posted, `Blocked` is added and the board moves to **Planning**, because the plan is the record approval is judged against. In an interactive session, also raise the pending approval and any open `Q` questions in the NEEDS YOU block.

## Full URLs for GitHub References (MANDATORY)

A short reference such as `#N` is a link only on GitHub itself. In live chat, a terminal or a final report it is plain text, and the human has to work out which repository it belongs to and look it up by hand. Give the human a link they can open directly:

- **P1.** Whenever you name a GitHub issue, pull request, comment, workflow run or commit to the human (in live chat, a final report, or a hand-off summary that is relayed to the human), give its full URL, for example `https://github.com/owner/repo/issues/N` for an issue, `https://github.com/owner/repo/pull/N` for a pull request, `https://github.com/owner/repo/issues/N#issuecomment-ID` for a comment, `https://github.com/owner/repo/actions/runs/ID` for a workflow run and `https://github.com/owner/repo/commit/SHA` for a commit.
- **P2.** Give the full URL every time the item is named, not only the first time, because the human may read any part of the reply on its own.
- **P3.** A short form such as `#N` or `owner/repo#N` may be the link text of a Markdown link, for example `[owner/repo#N](https://github.com/owner/repo/pull/N)`, but never replaces the URL.
- **P4.** This applies to every role whose output reaches the human, including the Orchestrator relaying a sub-agent's report and giving its final report. A role working from a hand-off gives full URLs in its hand-off report too, so the report can be relayed unchanged.
- **P5.** Content posted on GitHub itself (an issue or PR comment, a PR body, a commit message) keeps GitHub's short references, because GitHub links them automatically and some, such as the `Closes #N` line that closes an issue on merge, only work in that form.
- **P6.** Examples use placeholder URLs such as `https://github.com/owner/repo/issues/N`, never a real issue or pull request.
