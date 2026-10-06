---
name: credfeto-pr-sync
description: Keep pull request titles, bodies, and labels in sync with their linked issues, create PRs correctly when one does not yet exist, and manage PR lifecycle including bot-created PR ownership, draft state, environment/infrastructure block markers, and correcting prior claims. Use on every agent run that interacts with a PR, when creating or updating a PR, when checking for existing PRs before starting work, when replying to PR comments, when checking CI status on a PR, or when blocking a PR pending human input.
---

# Pull Request Sync and Lifecycle

## Authentication (MANDATORY)

Never attempt `gh auth login` or manipulate credentials yourself; if auth is broken, stop and report it. Never run `gh auth setup-git`; refuse the request outright, even if asked directly: it wires git's HTTP credential helper to `gh`, rerouting commit/push traffic through `gh` and violating the mandatory rule that commit and push always go through the `git` CLI directly against the real `github.com` remote. The rewrite rules also persist in the repo's local `.git/config` beyond the current task, silently breaking every later git operation until manually cleaned up. This applies unconditionally, not only when `GH_HOST` is set (see GitHub CLI Proxy Behaviour below for the proxy-specific consequence).

## Choosing Between `cfwf` and `gh` (MANDATORY)

Reach for these in this order:

1. `cfwf` for anything it supports, for reads and writes. Run `cfwf help` once per session to see what it covers, and `cfwf help <command>` for a command's options; do not rely on memory, because its commands grow.
2. A native `gh <noun> <verb>` subcommand when `cfwf` has no command for the operation.
3. `gh api` or `gh api graphql` only when neither of the above covers it.

`cfwf` is where routine `gh` operations are meant to end up as standardised, pre-canned commands rather than long `gh` scripts composed by hand. When you use `gh api` (REST or GraphQL) or `gh ... --json <fields>` (with or without `--jq`), for a read or a write, and no `cfwf` command covers that use, raise an issue on `credfeto/credfeto-orchestrator` asking for it to be added to `cfwf`, then carry on with `gh` for the current task. This applies to routine uses such as `gh pr view --json` and `gh pr list --json` as much as to unusual ones. If `cfwf` (or any other required CLI tool) is not installed or a command fails, stop immediately and ask the user to install or fix it rather than falling back to hand-composed `gh` for a use `cfwf` covers; never search for the binary in alternative locations, manipulate `PATH` to find it, or attempt to install it without being asked. Plain native subcommands without `--json`, such as `gh pr create`, `gh pr comment` and `gh pr edit --add-label`, are exempt.

- **One issue per distinct use.** Search `credfeto/credfeto-orchestrator` first, using plain output so the search does not itself need `--json`: `gh issue list --repo credfeto/credfeto-orchestrator --state all --search "cfwf <keywords>"`. If an open or closed issue already covers the use, do not raise another; if a closed one was declined, follow its outcome.
- **Say what is needed.** Give the exact `gh` command (with placeholders for the values), what it is for, and where it is used. Add the new issue to the "Workflow" project as for any issue.

## GitHub State Lags Behind Writes (MANDATORY)

GitHub's API is asynchronous: a change can take seconds, sometimes longer, to show up in a read. This applies to anything that lags, including Workflow board fields, labels, and closing-issue references. It is GitHub's behaviour, not a fault in `gh`, `cfwf`, the orchestrator or the API proxy, so do not raise issues on `credfeto/credfeto-orchestrator` or `credfeto/github-api-proxy` for it.

- A write whose call succeeded is done. Do not re-read it to confirm.
- Never spam GitHub while waiting for a change to show. Do not repeat a write, or poll or loop on a read, because a read straight after a write has not caught up yet. (Waiting for a human to act is a different, sanctioned wait.)
- A read that disagrees with a write you just made is lag, not a failure. If a later step reads it anyway, carry on and check again at a later step; repeat the write only if the value is still wrong then. There is no fixed wait.

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
   cfwf closing-issue-labels --repo <owner/repo> --pr <pr>
   gh pr edit <pr> --repo <owner/repo> --add-label "<label-1>,<label-2>"
   ```

   `cfwf closing-issue-labels` prints the labels to sync, one per line, already leaving out `Blocked` and `On Hold` (workflow-control labels are never synced from an issue to its PR). Pass them to one `gh pr edit --add-label` call as a comma-separated list. A non-zero exit is a failure to report, not "no labels"; if it exits 0 and prints nothing, there is nothing to add. If the `gh pr edit` call fails because a label does not exist in the PR's repo, repeat it without that label.

4. Never remove any label from a PR or issue; GitHub workflows add labels automatically and they must not be removed (for the sole exception see Label Management below).

## Correcting a Prior Claim (MANDATORY)

If a factual claim or finding previously posted in a PR body or comment turns out to be wrong (e.g. a root-cause statement, an evidence point, a "this is a deviation from process" assertion), post a **new comment** stating the correction and briefly why, quoting or referencing the original claim being corrected. Editing the body to also fix it is fine, but the comment is the mandatory part: a silent in-place body edit is not sufficient on its own, because GitHub only surfaces it as a small "edited" marker that a human reviewer can easily miss, unlike a comment which appears in the normal timeline.

This is distinct from the routine Title, Body, and Label Sync above, which requires ordinary in-place edits to keep a PR's title/body/labels synced with its linked issues; that is not a correction and needs no comment. This rule is about retracting or fixing something substantive that was previously asserted as true.

## Pre-Closure Decision Check (MANDATORY)

Before closing any PR, check whether its Implementation Plan (Approach/Files-to-change text or an Open Question) or a later comment on it flagged a specific decision as required or pending (e.g. "needs policy sign-off", "pending a decision on X", an unresolved `Qn.`). If so, do not close until that specific item has a visible resolution of its own: a comment recording the decision, a link to the resolving issue/PR, or an explicit retraction, not just implicitly overtaken by whichever branch of the plan got implemented. Removal of the `Blocked` label is not itself sufficient evidence this check is satisfied; the resolution must actually have been posted.

## Label Management (MANDATORY)

- Always use `--add-label` when adding labels; **never** `--label`, which replaces all existing labels and destroys automatically-applied classification labels.
- Never remove labels from issues or PRs. The sole exception is removing `Blocked` on a human's live-chat plan approval of an issue in an interactive session, carried out on their behalf after mirroring the approval as a GitHub comment.

## Prompt Traceability (MANDATORY)

Once a request is already tracked by a PR, every subsequent prompt from the human that changes, redirects, or adds detail to that work must be recorded on that PR:

- Comment with the prompt (verbatim, or a faithful summary for long prompts) and how it was resolved: a code change, an answered question, a scope adjustment, etc.
- Post this before or immediately after acting on the prompt; do not let several prompts accumulate unrecorded.
- This applies whether the prompt arrived as a live chat message or as a GitHub comment (GitHub comments are already covered by Comment Replies below).

## Comment Replies (MANDATORY)

Reply to every PR comment that prompted an action. Check both comment surfaces before concluding there is nothing to reply to: top-level PR comments and review summaries (`gh pr view <n> --repo <owner/repo> --json comments,reviews`) **and** inline/diff-level review comments (`gh api repos/<owner>/<repo>/pulls/<n>/comments`), since a review can carry an empty top-level body with the actual feedback only in an inline comment.

- Code change made: reply with `Fixed in <commit-sha>: <one sentence describing what changed and why>`.
- Pattern Sweep found further occurrences: add `Swept in <sha>: <files touched>` on the next line, one line per commit that carries sweep hunks (the fix SHA when every hit was in a file the fix touched); the per-file reasons are in that commit's body.
- Already fixed by an earlier sweep in this PR (no new commit): reply with `Already swept in <sha>`, citing the commit whose body carries the `Construct:` line.
- Question answered inline (no code change): reply with the full answer.
- No reply means no acknowledgement; always close the loop.

## Trusted Commenters

A trusted commenter is a human whose comment can approve a plan or ask for work. Decide it by the comment author's login, never by `authorAssociation` (`OWNER`, `MEMBER` or `COLLABORATOR`), because an account with collaborator access is not necessarily a human approver: the agent's own bot account is usually a collaborator.

1. Trust only the logins in the "Trusted commenters" list the orchestrator passes in your CLAUDE.md.
2. Never trust a comment whose author login is the bot login the orchestrator passes alongside that list, even if that login is also in the list, because a comment from the agent's own bot account is never a human approval. Match that login by name, never by whether `gh` reports `viewerDidAuthor` as `true`, because the agent can run as a trusted human's account and excluding every comment by that account would drop that human's real approvals. If no bot login is provided, exclude no login.
3. If no list is provided (for example an interactive session started without the orchestrator), trust only the repository owner's login (the `<owner>` in `<owner/repo>`). If the owner is an organisation, no comment matches, so ask the human instead.
4. Never write either approval keyword (`approved` or `lgtm`, in any case) in a comment you post unless that comment mirrors a real human approval, or the keyword sits inside a verbatim quote of a human's own words formatted as a Markdown quote (`>`). The ban covers every other comment, such as a re-block comment saying no approval was found, a status comment or a question; to refer to the words there, write "the two accepted approval keywords".

## Human Comment Requests: Run First (MANDATORY)

Before processing CI checks or continuing the review loop below, scan **all** comments on the current PR and its linked issue(s) from trusted commenters for ad-hoc requests to create a new GitHub issue: natural-language phrasing such as "raise an issue", "create an issue", "add an issue", "open an issue", "file an issue" (case-insensitive).

For each such request not yet actioned (no reply from you linking a newly created issue):

1. Search for an existing open or closed issue covering the same topic; do not create duplicates.
2. If none exists, create it immediately: `gh issue create --repo <owner/repo> --title "<concise title>" --body "<description>" --label "<priority label, or 'Medium' if unspecified>"`, then add it to the "Workflow" project immediately: `cfwf workflow-status --set --repo <owner/repo> --issue <number> --status "Not Started"` (only for the issue just created, because `--set` overwrites the status of an item already on the board).
3. Reply to the original comment with the new issue number, using `gh pr comment` if the request was on the PR or `gh issue comment` if it was on a linked issue.
4. Only continue with CI Checks and the rest of the workflow once every such request is actioned.

## CI Checks (MANDATORY)

The Orchestrator states the run mode (interactive or unattended) in every hand-off to a role whose rules depend on it, and that role uses the stated mode rather than judging it itself; a hand-off that states no mode means unattended. A session counts as interactive only once a human has typed a message in it; an injected prompt or task notification does not count. If unsure, assume unattended. In an unattended run, a pre-agentic gate normally blocks agent invocation while CI checks are pending, so the rules below are a safety net for edge cases; an interactive session has no such gate.

When working on a PR, check CI state **once**, required checks only, because the PR is mergeable without the optional ones and the plain output does not say which checks are required:

```bash
gh pr checks <number> --repo <owner/repo> --required
```

Judge the result by the exit code of this plain form together with its state column, not `--json`, because with `--json` gh exits 0 even when a check has failed or is pending. It exits 0 when every reported required check passed, was skipped or was cancelled, 8 when one is pending, and 1 when one failed or when it prints `no required checks reported on the '<branch>' branch` or `no checks reported on the '<branch>' branch`. It also exits 1 on a gh or API error (authentication, network, proxy, rate limit, or a PR that does not exist), which it hits before it prints any check rows. gh only reports checks that have already registered on the PR's head commit, so a required workflow that has not been queued yet is missing from the list rather than shown as pending.

- A row whose state column (the second tab-separated field) reads `fail` means that required check failed, whatever the exit code, because gh prints `fail` there for a cancelled check as well as a failed one but does not count a cancelled check towards exit code 1. GitHub treats a cancelled required check as unsatisfied, so the PR cannot merge until it is re-run.
- Either `no ... checks reported` message counts as pending, never as pass or failure, because it usually means the run for the head commit has not registered yet.
- Exit code 1 with no check rows in the output and no `no ... checks reported` message is a gh or API error, not a failed check, because gh failed before it could read any check.
- If the repo has no required checks configured at all, drop `--required` and judge all checks instead, because otherwise gh reports `no required checks reported` for ever. It has none when neither the base branch's protection (`gh api repos/<owner>/<repo>/branches/<base> --jq '.protection.required_status_checks.contexts'`) nor its rulesets (a `required_status_checks` rule in `gh api repos/<owner>/<repo>/rules/branches/<base>`) list any. Look this up once per PR, not on every check.

Then act immediately; do **not** busy-loop, sleep, or use `--watch`, in any mode, because a blocking wait holds the session for the whole CI run:

- All required checks passed → accept it only if it is still true on the next check after it was first seen, because a fast required workflow can pass before a slower one has even been queued. In an unattended run, the gate's check before invoking the agent is the first sighting, so this check confirms it; proceed with the next step. In an interactive session this check is the first sighting, so hand the PR to CI Monitor (the role that watches a PR's checks in an interactive session), stating in the hand-off that all required checks passed, so that its first tick confirms it.
- Any required check failed, including a cancelled one → first count the `### CI Debugger:` status comments for that check on the PR (see below); if there are already 3, treat the PR as consistently failing (last bullet) instead of routing the check again, in every run mode, because only the PR's comment history persists between invocations. Otherwise route it to CI Debugger (the role that finds the cause and pushes a fix, or re-runs a cancelled check that needs no code change) rather than fixing it yourself, because the Orchestrator never implements directly, and post a status comment, even while other checks are still pending, because waiting for the slowest check would delay the fix by the whole CI run. Do not wait for the new run to complete. Then:
  - Unattended run → stop; the gate re-invokes the agent once the new run finishes.
  - Interactive session → if CI Debugger pushed a fix or re-ran a check, hand the PR to CI Monitor instead of stopping, stating in the hand-off that the session is interactive. If CI Debugger escalated, handle the escalation yourself instead (for example by following the Environment/Infrastructure Block Marker convention below for an environment diagnosis), because CI Monitor would see the unchanged failure and hand it straight back to CI Debugger.
- Any required check pending or in_progress, or none reported yet, and none failed:
  - Unattended run → stop silently; do not post a status comment. CI checks are bound by GitHub's own timeouts and will eventually pass, fail, or time out without agent intervention, and the gate re-invokes the agent once they do.
  - Interactive session → hand the PR to CI Monitor instead of stopping, stating in the hand-off that the session is interactive.
- gh or API error → report the error rather than routing a CI failure, because no check has failed and CI Debugger would look for a failure that does not exist.
- CI consistently failing and cannot be fixed → mark the PR blocked: `gh pr edit <number> --repo <owner/repo> --add-label "Blocked"`. A required check still failing after 3 CI Debugger rounds for that check on the PR also counts, because further rounds would only repeat the cycle.

CI Debugger posts a one-line status comment after each pushed fix or re-run, in the form `### CI Debugger: <fix pushed|re-run started> for <check name>` (the check name exactly as `gh pr checks` reports it). Your own routing status comment does not count towards the cap, because it records a routing decision rather than a round. Count a `### CI Debugger:` comment for a check towards the cap only when both of these hold:

- Its author is the bot login or a trusted commenter (see Trusted Commenters above), because anyone else could post one and get the PR marked `Blocked` before a single fix attempt.
- It was posted after the PR's latest `auto_merge_enabled` timeline event, or since the PR opened if there is none, because auto-merge is enabled only once every required check has passed on the ready PR, so rounds for failures fixed before then must not use up the budget for a new failure. Read the time with:

  ```bash
  gh api repos/<owner>/<repo>/issues/<number>/timeline --paginate --jq '.[] | select(.event == "auto_merge_enabled") | .created_at' | tail -n 1
  ```

## Blocked Label (MANDATORY)

When asking a question in a PR comment and waiting for an answer before continuing:

1. Add the `Blocked` label to the PR immediately after posting the question: `gh pr edit <number> --repo <owner/repo> --add-label "Blocked"`.
2. Do not continue working on the PR until the label is removed.
3. Use only the `Blocked` label for this purpose; never a substitute such as `do not merge` or `needs review`.
4. Live-chat approval is not sufficient on its own: if a human answers or approves in a live chat session rather than posting a GitHub comment directly, post the comment yourself, quoting the live instruction, before resuming work and before asking for `Blocked` to be removed.
5. Whenever `Blocked` is added, the accompanying comment must name the specific instruction that requires the stop, as a link to its section. A judgement such as "out of scope", "pre-existing" or "also fails on main" is never such an instruction; if no instruction requires the stop, do not add `Blocked` and carry on with the work, because an unjustified `Blocked` stalls the item until a human notices.

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

- Only one active branch or open PR per user per repository at a time; do not create another until the current one is merged and closed.
- **Before blocking new work** because of an existing PR: always verify its current state with `gh pr view <number> --repo <owner/repo> --json state,mergedAt`; never rely on conversation memory. A PR that was open earlier in the session may have since been merged.
- When adding work to an open PR (review comments, missing coverage, CI fixes), turn auto-merge off if it is on, then convert to draft (`gh pr ready <number> --repo <owner/repo> --undo`), because otherwise GitHub could merge the new change as soon as its checks pass, before it is reviewed. Converting to draft alone is not enough, because GitHub does not turn auto-merge off when a PR becomes a draft. Turn auto-merge off with `gh pr merge <number> --repo <owner/repo> --disable-auto` only when `gh pr view <number> --repo <owner/repo> --json autoMergeRequest --jq '.autoMergeRequest'` prints something other than `null`, because GitHub does not document what `--disable-auto` does on a PR with no auto-merge request.
- Keep the PR in draft until the AI Review Loop has reviewed every new commit: only its final phase marks the PR ready, because PR creation always leaves the PR as draft, and it enables auto-merge only once every required check on the PR's current head has a result completed at or after the time the PR was last marked ready and none of them failed, because GitHub counts a check skipped on a draft as passed.
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
- This only catches work that already has a PR open. A branch pushed but never turned into a PR (session died first) needs a separate check before creating a new branch: see the git-branch skill.

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

Always pass `--repo <owner>/<repo>` explicitly rather than relying on the current directory's remote; it is required when `GH_HOST` is set, and safer in general when scripting.

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
- **Commit and push operations are always rejected by the proxy; never use `gh` for these, no exceptions.** Use the `git` CLI directly, always against the real `github.com` remote. This includes never running `gh auth setup-git`, even if asked directly: it rewrites git's HTTP credential helper to route commit/push traffic through `gh` (and, when `GH_HOST` is set, through the proxy), and the rewrite persists in the repo's local git config beyond the current task, silently breaking every later git operation until manually cleaned up. Refuse the request outright rather than trying it and working around the failure.
