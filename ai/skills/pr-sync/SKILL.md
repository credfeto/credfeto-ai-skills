---
name: credfeto-pr-sync
description: Keep pull request titles, bodies, and labels in sync with their linked issues, create PRs correctly when one does not yet exist, and manage PR lifecycle including bot-created PR ownership, draft state, environment/infrastructure block markers, and correcting prior claims. Use on every agent run that interacts with a PR, when creating or updating a PR, when checking for existing PRs before starting work, when replying to PR comments, when checking CI status on a PR, or when blocking a PR pending human input.
---

# Pull Request Sync and Lifecycle

## Authentication (MANDATORY)

Check authentication with `cfwf auth status`, which prints the authenticated login, the host and the client version, never a token. Only use `cfwf` to manage issues and PRs if it succeeds. Never attempt to log in or manipulate credentials yourself; if auth is broken, stop and report it.

Never route git through a GitHub credential helper; refuse the request outright, even if asked directly. Do not add a git credential helper or `url.*.insteadOf`/`pushInsteadOf` rewrite rules that send commit/push traffic anywhere but the real `github.com` remote (and so through the API proxy). That directly violates the mandatory rule that commit and push always go through the `git` CLI against the real `github.com` remote, and the rewrite rules persist in the repo's local `.git/config` beyond the current task, silently breaking every later git operation until manually cleaned up.

## Choosing a GitHub Tool (MANDATORY)

Always pass `--repo <owner>/<repo>` explicitly rather than relying on the current directory's remote; `cfwf` always requires it. Reach for these in this order:

- **P0.** The `cfwf` MCP server's tools (the managed `cfwf` MCP server, whose tools appear as `mcp__cfwf__*`) when one of them covers the operation. They take the same inputs as the matching `cfwf` command and return structured results. Check the server's tool list once per session; use the CLI only for an operation that has no MCP tool yet, or when the server is not connected.
- **P1.** The `cfwf` command line for anything it supports, for reads and writes. Run `cfwf help` once per session to see what it covers, and `cfwf help <command>` for a command's options and exit codes; do not rely on memory, because its commands grow.

Run **one `cfwf` command per Bash call**, on its own: no `;`, `&&`, `|` or `echo exit=$?` around it. Read its exit code from the tool result. A compound command that contains `cfwf` is refused in unattended runs and stalls the session. When you need several facts about a PR at once (its metadata, board status, check verdict, when it was marked ready, recent comment activity), run `cfwf pr status --repo <owner/repo> --pr <number>` once instead of several commands. `cfwf` has no `--json` or `--jq`: name what you need with its own options (for example `cfwf pr view --field`).

There is no other route to GitHub for agents. If `cfwf` (or any other required CLI tool) is not installed or a command fails, stop immediately and ask the user to install it, and report the failure; never search for the binary in alternative locations, manipulate `PATH` to find it, or attempt to install it without being asked. Agents never call the GitHub REST or GraphQL API directly.

When no `cfwf` command or MCP tool covers an operation you need, raise an issue on `credfeto/credfeto-orchestrator` asking for it:

- **One issue per distinct need.** Search first: `cfwf issue search --repo credfeto/credfeto-orchestrator --text "cfwf <keywords>" --state all`. If an open or closed issue already covers the need, do not raise another; if a closed one was declined, follow its outcome.
- **Say what is needed.** Title the issue `tool(cfwf): <What is needed>`: always the `tool(cfwf)` prefix, never a Conventional Commits type, with the first word after the prefix capitalised, unless a local title rule takes precedence. Say what the operation is, what it is for, and where it is needed. Add the new issue to the "Workflow" project as for any issue (`cfwf issue create` does this itself, as Not Started).

Never hand-assemble a complex or multi-step operation from repeated commands, such as a wait loop around `cfwf pr checks`. If `cfwf` has no command for it, raise a `tool(cfwf):` issue as above, and until it is added do one safe, read-only check of the current state and report it.

## GitHub State Lags Behind Writes (MANDATORY)

GitHub's API is asynchronous: a change can take seconds, sometimes longer, to show up in a read. This applies to anything that lags, including Workflow board fields, labels, and closing-issue references. It is GitHub's behaviour, not a fault in `cfwf`, the orchestrator or the API proxy, so do not raise issues on `credfeto/credfeto-orchestrator` or `credfeto/github-api-proxy` for it.

- A write whose call succeeded is done. Do not re-read it to confirm.
- Never spam GitHub while waiting for a change to show. Do not repeat a write, or poll or loop on a read, because a read straight after a write has not caught up yet. (Waiting for a human to act is a different, sanctioned wait.)
- A read that disagrees with a write you just made is lag, not a failure. If a later step reads it anyway, carry on and check again at a later step; repeat the write only if the value is still wrong then. There is no fixed wait.

## Check Live State Before Asking or Reporting (MANDATORY)

Before asking the human a question, or reporting that something is waiting on them (an approval, a review, a merge, a manual step), gather the answer yourself from what a command can show, because a question a command could have answered costs the human time and a stale report misleads them. For a PR, read it in one call first with `cfwf pr status --repo <owner/repo> --pr <number>`, which prints the board status, review decision, merge state, auto-merge, labels, check verdict, ready-at and comment counts together. Use single-purpose reads only for detail it does not print: the Workflow board status (`cfwf workflow-status --check --repo <owner/repo> --pr <n>`), the comments, reviews and review threads (`cfwf pr comments --repo <owner/repo> --pr <number>`), and when the PR was last marked ready (`cfwf pr ready-at --repo <owner/repo> --pr <number>`).

Read state that can change (the review decision, the merge state, auto-merge and check states) immediately before reporting it, without polling, and never present an earlier read as current. Ask only for what no command can show, such as a design choice, an approval, a priority or a fact about the human's own environment, and when you ask or report that something is waiting on the human, say what you checked and what it returned.

## PR Creation (MANDATORY)

After pushing a commit that should be associated with a PR:

1. Wait up to 1 minute for GitHub to auto-create a PR: `cfwf pr list --repo <owner/repo> --head <branch>`. If it is still absent, create one with `cfwf pr create --repo <owner/repo> --head <branch> --title "<title>" --body-file -` (body on stdin), which opens it as a draft on the Workflow board as **Development**, or prints the existing PR's URL if the branch already has one.
2. Title: Conventional Commits format matching the primary commit. For a placeholder-only commit that opens the PR before any code exists, take the Conventional Commits type from the expected change or from the issue's labels instead (e.g. `bug` gives `fix`, `enhancement` gives `feat`), and correct it once the primary code commit lands if it differs. Never take the PR title or its type from the issue title, because issue titles use prefixes (e.g. `learning:`, `audit:`, `tool(cfwf):`) that are not Conventional Commits types.
3. Body: a summary of the change plus `Closes #<n>` for each linked issue (or `Related to #<n>` if it does not fully close the issue).
4. If the PR already exists, update the body rather than creating a duplicate: `cfwf pr edit --repo <owner/repo> --pr <number> --body-file <file|->`.
5. Add yourself as assignee: `cfwf pr edit --repo <owner/repo> --pr <number> --assign-self`.
6. Leave the PR as draft; do not mark it ready or enable auto-merge as part of creation. That happens only after the full review process for the work item is satisfied.

## Title, Body, and Label Sync (MANDATORY: every PR interaction)

On every agent run, for every PR being interacted with:

1. Ensure the **title** accurately reflects all changes in the PR; update it if the scope has changed.
2. Ensure the **body** summarises all changes and includes `Closes #<n>` for each linked issue, if any.
3. Sync labels from all linked closing issues to the PR:

   ```bash
   cfwf pr sync-labels --repo <owner/repo> --pr <pr> [--assign-self]
   ```

   `cfwf pr sync-labels` adds the labels of every issue the PR closes to the PR, one label at a time, never removing one and never adding `Blocked` or `On Hold` (workflow-control labels are never synced from an issue to its PR). It prints each label it added, then `<url> synced`; exit 0 means synced, nothing to add included. A label the PR's repository does not have is skipped with a warning; mention it in your report. A non-zero exit is a failure to report, not "no labels": exit 1 can mean a closing issue could not be read after the others' labels were added. `--assign-self` also assigns the agent to the PR. `cfwf closing-issue-labels --repo <owner/repo> --pr <pr>` only prints the labels it would sync.

4. Never remove any label from a PR or issue; GitHub workflows add labels automatically and they must not be removed (for the sole exceptions see Label Management below).

## Correcting a Prior Claim (MANDATORY)

If a factual claim or finding previously posted in a PR body or comment turns out to be wrong (e.g. a root-cause statement, an evidence point, a "this is a deviation from process" assertion), post a **new comment** stating the correction and briefly why, quoting or referencing the original claim being corrected. Editing the body to also fix it is fine, but the comment is the mandatory part: a silent in-place body edit is not sufficient on its own, because GitHub only surfaces it as a small "edited" marker that a human reviewer can easily miss, unlike a comment which appears in the normal timeline.

This is distinct from the routine Title, Body, and Label Sync above, which requires ordinary in-place edits to keep a PR's title/body/labels synced with its linked issues; that is not a correction and needs no comment. This rule is about retracting or fixing something substantive that was previously asserted as true.

## Pre-Closure Decision Check (MANDATORY)

Before closing any PR, check whether its Implementation Plan (Approach/Files-to-change text or an Open Question) or a later comment on it flagged a specific decision as required or pending (e.g. "needs policy sign-off", "pending a decision on X", an unresolved `Qn.`). If so, do not close until that specific item has a visible resolution of its own: a comment recording the decision, a link to the resolving issue/PR, or an explicit retraction, not just implicitly overtaken by whichever branch of the plan got implemented. An Open Question already blocks via the `Blocked`-label approval gate, and removal of that label is not itself sufficient evidence this check is satisfied; the resolution must actually have been posted.

## Label Management (MANDATORY)

- Only ever add labels; never replace an item's whole label set, which destroys automatically-applied classification labels. Add labels with `cfwf label add --repo <owner/repo> (--issue <n> | --pr <n>) --label <name>`, which only ever adds.
- Never remove labels from issues or PRs. GitHub workflows add classification labels automatically; removing them breaks automation. The sole exceptions are removing `Blocked` on a human's live-chat plan approval of an issue in an interactive session, and removing `Blocked` on a PR question the human answered in live chat (see Blocked Label below), each carried out on their behalf after mirroring the approval or answer as a GitHub comment.

## Prompt Traceability (MANDATORY)

Once a request is already tracked by a PR, every subsequent prompt from the human that changes, redirects, or adds detail to that work must be recorded on that PR:

- Comment with the prompt (verbatim, or a faithful summary for long prompts) and how it was resolved: a code change, an answered question, a scope adjustment, etc.
- Post this before or immediately after acting on the prompt; do not let several prompts accumulate unrecorded.
- This applies whether the prompt arrived as a live chat message or as a GitHub comment (GitHub comments are already covered by Comment Replies below).

## Comment Replies (MANDATORY)

Reply to every PR comment that prompted an action. Check both comment surfaces before concluding there is nothing to reply to: top-level PR comments and review summaries **and** inline/diff-level review comments, which `cfwf pr comments --repo <owner/repo> --pr <n>` prints together; a review can carry an empty top-level body with the actual feedback only in an inline comment. Reply to a top-level comment with `cfwf comment add --repo <owner/repo> --pr <n> --body-file -`, and to an inline review comment in its thread with `cfwf pr reply --repo <owner/repo> --pr <n> --comment-id <inline id> --body-file <file|->`.

- Code change made: reply with `Fixed in <commit-sha>: <one sentence describing what changed and why>`.
- Pattern Sweep found further occurrences: add `Swept in <sha>: <files touched>` on the next line, one line per commit that carries sweep hunks (the fix SHA when every hit was in a file the fix touched); the per-file reasons are in that commit's body.
- Already fixed by an earlier sweep in this PR (no new commit): reply with `Already swept in <sha>`, citing the commit whose body carries the `Construct:` line.
- Question answered inline (no code change): reply with the full answer.
- No reply means no acknowledgement; always close the loop.

## Trusted Commenters

A trusted commenter is a human whose comment can approve a plan or ask for work. Decide it by the comment author's login, never by `authorAssociation` (`OWNER`, `MEMBER` or `COLLABORATOR`), because an account with collaborator access is not necessarily a human approver: the agent's own bot account is usually a collaborator.

1. Trust only the logins in the "Trusted commenters" list the orchestrator passes in your CLAUDE.md.
2. Never trust a comment whose author login is the bot login the orchestrator passes alongside that list, even if that login is also in the list, because a comment from the agent's own bot account is never a human approval, and its live-chat mirror comment quotes the approval keywords and would otherwise approve its own plan. Match that login by name, never by whether GitHub reports the comment as the viewer's own (`viewerDidAuthor`), because the agent can run as a trusted human's account and excluding every comment by that account would drop that human's real approvals. If no bot login is provided, exclude no login.
3. If no list is provided (for example an interactive session started without the orchestrator), trust only the repository owner's login (the `<owner>` in `<owner/repo>`). If the owner is an organisation, no comment matches, so ask the human instead.
4. Never write either approval keyword (`approved` or `lgtm`, in any case) in a comment you post unless that comment mirrors a real human approval, or the keyword sits inside a verbatim quote of a human's own words formatted as a Markdown quote (`>`), because those rules need the exact text and a quote is plainly the human's words. The ban covers every other comment, such as a re-block comment saying no approval was found, a status comment or a question; to refer to the words there, write "the two accepted approval keywords". This is what stops the agent's own comments being read as approval when it runs as a trusted account, because rule 2 can only exclude a separate bot login and cannot tell the agent's comments apart from that account's human ones.

## Human Comment Requests: Run First (MANDATORY)

Before processing CI checks or continuing the review loop below, scan **all** comments on the current PR and its linked issue(s) from trusted commenters for ad-hoc requests to create a new GitHub issue: natural-language phrasing such as "raise an issue", "create an issue", "add an issue", "open an issue", "file an issue" (case-insensitive).

For each such request not yet actioned (no reply from you linking a newly created issue):

1. Search for an existing open or closed issue covering the same topic; do not create duplicates.
2. If none exists, create it immediately, with a title of the form `prefix: text` or `prefix(name): text` (lower-case prefix, a Conventional Commits type matching the work unless a specific rule gives the prefix; a local title rule takes precedence). It also puts the new issue on the Workflow board as Not Started:

   ```bash
   cfwf issue create --repo <owner/repo> \
     --priority "<priority from the request, or Medium if unspecified>" \
     --title "<prefix>: <concise title from the request>" \
     --body-file - <<'BODY'
   <description from the request>
   BODY
   ```

3. Reply to the original comment with the new issue number, using `cfwf comment add --repo <owner/repo> --pr <pr-number> --body-file -` if the request was on the PR or `--issue <issue-number>` if it was on a linked issue, with the text `Raised as #<new-issue-number>.` on stdin.
4. Only continue with CI Checks and the rest of the workflow once every such request is actioned.

## CI Checks (MANDATORY)

The Orchestrator states the run mode (interactive or unattended) in every hand-off to a role whose rules depend on it, and that role uses the stated mode rather than judging it itself; a hand-off that states no mode means unattended. A session counts as interactive only once a human has typed a message in it; an injected prompt or task notification does not count. If unsure, assume unattended. In an unattended run, the `oneshot` pre-agentic gate normally blocks agent invocation while CI checks are pending, so the rules below are a safety net for edge cases; an interactive session has no such gate.

When working on a PR, check CI state **once**, required checks only, because the PR is mergeable without the optional ones:

```bash
cfwf pr checks --repo <owner/repo> --pr <number>
```

It reads the required checks of the PR's base branch from its protection and rulesets (every check when the branch requires none), judges the newest run of each on the PR's current head, and never waits. Judge the result by its exit code, never its printed text:

- **0** every required check passed (skipped and neutral count as passed).
- **3** at least one required check failed; a cancelled, timed-out or stale one counts as failed, because GitHub treats it as unsatisfied and the PR cannot merge until it runs again. The rows reading `fail` name them.
- **4** none failed and at least one is pending, including a required check with no result yet.
- **5** the head has no check runs or statuses at all. That is not a pass; treat it as pending, because it usually means the run for the head commit has not registered yet, or the repository's checks only start once the PR is marked ready.
- **1** an API or network error, never a failed check. **2** a usage error.

Then act immediately; do **not** wait for the checks to settle yourself, in any mode, because a blocking wait holds the session for the whole CI run. Only the CI Monitor role waits for checks, in the background, with `cfwf pr checks-wait --repo <owner/repo> --pr <n> [--timeout-minutes <m>]` started with `run_in_background: true`:

- All required checks passed → accept it only if it is still true on the next check after it was first seen, because a fast required workflow can pass before a slower one has even been queued. In an unattended run, the `oneshot` gate's check before invoking the agent is the first sighting, so this check confirms it; proceed with the next step. In an interactive session this check is the first sighting, so hand the PR to CI Monitor, stating in the hand-off that the session is interactive, because its `cfwf pr checks-wait` run confirms the pass on two reads of its own.
- Any required check failed, including a cancelled one → first count the `### CI Debugger:` status comments for that check on the PR (see below); if there are already 3, treat the PR as consistently failing (last bullet) instead of routing the check again, in every run mode, because only the PR's comment history persists between invocations. Otherwise route it to CI Debugger (the role that finds the cause and pushes a fix, or re-runs a cancelled check that needs no code change) rather than fixing it yourself, because the Orchestrator never implements directly, and post a status comment, even while other checks are still pending, because waiting for the slowest check would delay the fix by the whole CI run. Do not wait for the new run to complete. Then:
  - Unattended run → stop; `oneshot` re-invokes the agent once the new run finishes.
  - Interactive session → if CI Debugger pushed a fix or re-ran a check, hand the PR to CI Monitor instead of stopping, stating in the hand-off that the session is interactive. If CI Debugger escalated, handle the escalation yourself instead (for example by following the Environment/Infrastructure Block Marker convention below for an environment diagnosis), because CI Monitor would see the unchanged failure and hand it straight back to CI Debugger.
- Any required check pending or in_progress, or none reported yet, and none failed:
  - Unattended run → stop silently; do not post a status comment. CI checks are bound by GitHub's own timeouts and will eventually pass, fail, or time out without agent intervention, and `oneshot` re-invokes the agent once they do.
  - Interactive session → hand the PR to CI Monitor instead of stopping, stating in the hand-off that the session is interactive.
- API or network error (exit 1) → report the error rather than routing a CI failure, because no check has failed and CI Debugger would look for a failure that does not exist.
- CI consistently failing and cannot be fixed → mark the PR blocked: post the diagnosis and add `Blocked` with `cfwf pr block --repo <owner/repo> --pr <number> --body-file <file|->`. A required check still failing after 3 CI Debugger rounds for that check on the PR also counts, whether CI Monitor reports it or the failed-check branch above finds it, because further rounds would only repeat the cycle.

An analyzer findings comment (`<!-- sarif-summary: ... -->`) on the PR is handled by the sarif-summary-findings skill.

CI Debugger posts a one-line status comment after each pushed fix or re-run, in the form `### CI Debugger: <fix pushed|re-run started> for <check name>` (the check name exactly as `cfwf pr checks` reports it). Your own routing status comment does not count towards the cap, because it records a routing decision rather than a round. Count a `### CI Debugger:` comment for a check towards the cap only when both of these hold:

- Its author is the bot login or a trusted commenter (see Trusted Commenters above), because anyone else could post one and get the PR marked `Blocked` before a single fix attempt.
- It was posted after the PR's latest `auto_merge_enabled` timeline event, or since the PR opened if there is none, because auto-merge is enabled only once every required check has passed on the ready PR, so rounds for failures fixed before then must not use up the budget for a new failure. Read that time with `cfwf pr auto-merge-at --repo <owner/repo> --pr <number>`: its `enabled-at` line, which is `-` when auto-merge was never enabled.

## Blocked Label (MANDATORY)

When asking a question in a PR comment and waiting for an answer before continuing:

1. Add the `Blocked` label to the PR immediately after posting the question. Do both with one command, which posts the question, then adds `Blocked`, leaving the board as it is: `cfwf pr block --repo <owner/repo> --pr <number> --body-file <file|->`.
2. Do not continue working on the PR until the label is removed.
3. Use only the `Blocked` label for this purpose; never a substitute such as `do not merge` or `needs review`. The orchestrator only recognises `Blocked` when deciding whether to skip an item.
4. Live-chat approval is not sufficient on its own: if a human answers or approves in a live chat session rather than posting a GitHub comment directly, post the comment yourself, quoting the live instruction, before resuming work and before asking for `Blocked` to be removed. The record must survive even if the chat session is lost.
5. Whenever `Blocked` is added, the accompanying comment must name the specific instruction that requires the stop, as a link to its section. A judgement such as "out of scope", "pre-existing" or "also fails on main" is never such an instruction; if no instruction requires the stop, do not add `Blocked` and carry on with the work, because an unjustified `Blocked` stalls the item until a human notices.
6. **A live-chat answer clears a PR's question `Blocked` in an interactive session.** When the human answers in live chat every open question that caused a PR's `Blocked`, do not wait for them to remove the label:
   - Post the mirror comment on the PR quoting the answer, as in rule 4.
   - Re-read the PR's live state (labels, comments, checks) and confirm no other open question, failed required check, environment-block marker (`<!-- orchestrator:env-block`) or round-cap `Blocked` remains; otherwise leave `Blocked` and tell the human what is still open.
   - Remove the label with `cfwf label remove --repo <owner/repo> --pr <number> --label Blocked`, then carry on straight away. It removes `Blocked` only when the agent added it last; if it exits 8 (a human added it), leave it and tell the human it is theirs to remove.
   - A partial answer, a question back or a qualified answer does not clear it; if in doubt, ask.
   - An unattended run never applies this; `Blocked` there still waits for the human.
7. Wherever the human is still the one who has to act (an approval, an answer, a manual step), say so once, plainly, at the top of the message, not only at the end of each status update.

## Environment/Infrastructure Block Marker (MANDATORY, PRs only)

When a Blocked-ing failure is diagnosed as an environment/infrastructure problem (a bug in the container image, a missing tool, a transient infra issue) rather than a bug in the PR's own code, add a machine-readable marker alongside the diagnosis so `oneshot` can auto-clear `Blocked` once the fix has actually shipped, instead of the PR sitting blocked until a human happens to notice:

1. Post the full human-readable diagnosis as normal: root cause, evidence, and (if known) the fix needed.
2. Append a single trailer line to that same comment:

   ```text
   <!-- orchestrator:env-block image-sha=${IMAGE_SHA_DEVELOPMENT_AGENT} -->
   ```

   Read `IMAGE_SHA_DEVELOPMENT_AGENT` from your own container environment (the same value printed at session start as part of "Image layer provenance"); this records which image build was current when the diagnosis was made.
3. Apply `Blocked` exactly as in the section above.
4. Use this marker **only** for a genuine environment/infrastructure diagnosis. `oneshot` auto-clears `Blocked` the moment it observes a differently-built agent image, with no further human involvement; marking a real code question or design decision this way would resume work before a human actually answered it.

This convention only applies to PRs (there is no container session, and therefore no image to diagnose against, before a PR/branch exists). Everything else about the Blocked-label convention above is unchanged.

## PR Lifecycle

- Only one active branch or open PR per user per repository at a time; do not create another until the current one is merged and closed.
- **Before blocking new work** because of an existing PR: always verify its current state with `cfwf pr view --repo <owner/repo> --pr <number> --field state --field merged-at`; never rely on conversation memory. A PR that was open earlier in the session may have since been merged.
- When adding work to an open PR (review comments, missing coverage, CI fixes), take it back with `cfwf pr take-back --repo <owner/repo> --pr <number> --body-file <file|->`, with a body saying why (the change about to be made). It turns auto-merge off first, then converts the PR to draft, moves the board to **Development** and posts the body as a comment. The order matters: converting to draft alone is not enough, because GitHub does not turn auto-merge off when a PR becomes a draft, so the PR would merge as soon as it is marked ready again, before the AI Review Loop has reviewed the fix. Never do these steps separately, and never mark a PR ready, convert it to draft, or turn auto-merge on or off by any route other than `cfwf pr hand-off` and `cfwf pr take-back`.
- Keep the PR in draft until the AI Review Loop has reviewed every new commit: only its final phase marks the PR ready, because PR creation always leaves the PR as draft, and its `cfwf pr hand-off` enables auto-merge only once every required check on the PR's current head has a result completed at or after the time the PR was last marked ready and none of them failed, because GitHub counts a check skipped on a draft as passed.
- Assign yourself to PRs when creating or updating: `cfwf pr edit --repo <owner/repo> --pr <number> --assign-self`.

## Bot-Created PRs (MANDATORY: treat as your own)

GitHub is configured to automatically create PRs from pushed branches. These PRs appear authored by `app/github-actions` but the commits are authored by you. They are your work; treat them identically to PRs you created yourself.

Before starting any work in a repository:

1. Run `cfwf pr list --repo <owner/repo>`, which lists every open PR, whoever authored it.
2. For any PR authored by `app/github-actions`, check the commit authors: `cfwf pr view --repo <owner/repo> --pr <n> --field commit-authors`.
3. If **all commits** are from your account (you are the sole committer), **take ownership**: update the PR title and body to match the proper format (summary, `Closes #<n>`, test plan), add yourself as assignee, and treat it as your active PR for that repo.
4. If commits are from multiple authors (e.g. you plus a human or Copilot), do **not** take over; leave the PR as-is and do not claim it as yours.
5. Do **not** create a new branch or PR for the same issue; that would be duplicate work.

**Checking for existing work before branching (MANDATORY):**

- Check branch names in all open PRs, not just PR authors. If any open PR's `headRefName` contains the issue number, that is your work from a prior session; resume it instead of creating a new branch.
- This only catches work that already has a PR open. A branch pushed but never turned into a PR (session died first) needs a separate check before creating a new branch: `git -C <dir> ls-remote --heads origin "*/<issue-number>-*"`. With no match, branch fresh from `main` as normal. With a match, run `git -C <dir> fetch origin <branch>` and `git -C <dir> rev-list --count origin/main..origin/<branch>`: `0` (not ahead of `main`) means branch fresh from `main`; more than `0` means check it out and continue from there instead of branching again, rebasing first if `origin/main` has advanced.

When you find a duplicate pair (a bot-created PR and one you authored yourself, for the same issue or branch):

- Keep whichever has the more complete body and later review activity.
- Close the other with a comment explaining which PR supersedes it: `cfwf pr close --repo <owner/repo> --pr <number> --body-file -`, with the explanation on stdin, posts the comment, then closes the PR.

## Comment and Body Text (MANDATORY: HEREDOC, never `\n`)

Every `cfwf` command that posts text takes it from a file (`--body-file`, `--description-file`), with `-` reading it from stdin; there is no inline `--body`. Pass multi-line text on stdin with a HEREDOC, or write it to a file first, so real newline characters are embedded. **Never** use escaped `\n` sequences in `cfwf` input; GitHub renders them as literal backslash-n characters, not line breaks:

```bash
cfwf comment add --repo <owner/repo> --pr <number> --body-file - <<'COMMENT'
First paragraph.

Second paragraph.
COMMENT
```

Only one input of a command can be `-`.

## Command Failure Reporting (MANDATORY)

When any git command fails (push, rebase, fetch, etc.), quote the exact stdout and stderr output verbatim in any issue or PR comment before posting any explanation or diagnosis. Never substitute a narrative about why a command might have failed for the actual error output. Run the failing command as its own call, then paste its output, unchanged, into the comment body as a separate call, quoting the heredoc delimiter (`'COMMENT'`) so the shell does not expand `$` or backticks that appear in the pasted output:

```bash
cfwf comment add --repo <owner/repo> --pr <number> --body-file - <<'COMMENT'
git push failed with:

<exact stdout and stderr of the failed command>
COMMENT
```

AI-generated diagnoses of command failures are frequently wrong; the verbatim output is always correct and the explanation is not.

## GitHub API Proxy (MANDATORY)

GitHub API traffic from `cfwf` may go through an API proxy:

- **Commit and push never go through the proxy or the GitHub API, no exceptions.** Use the `git` CLI directly, always against the real `github.com` remote.
- **Check a PR out with git**; there is no checkout command. For a review that makes no commits: `git -C <dir> fetch origin pull/<number>/head`, then `git -C <dir> switch --detach FETCH_HEAD`, run back to back so that no other fetch rewrites `FETCH_HEAD` in between. This checks out the PR head with no local branch, and works for a fork PR too. When the review is done, switch back to the branch being worked on (`git -C <dir> switch <branch>`). To add commits to a same-repository PR: `git -C <dir> fetch origin <headRefName>`, then `git -C <dir> switch <headRefName>`, then `git -C <dir> merge --ff-only origin/<headRefName>`; if it cannot fast-forward, stop and report it. Never create a separate review branch. A fork PR's commits live on the fork, so commits cannot be pushed to it through `origin`.
- If a `cfwf` command fails with what looks like a proxy error rather than a GitHub one, raise an issue on `credfeto/github-api-proxy` with the exact command, the API method (if visible), and the full error message verbatim.
