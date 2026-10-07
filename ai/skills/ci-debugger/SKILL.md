---
name: credfeto-ci-debugger
description: Diagnose a failing CI check by reading its full logs and finding the root cause, fixing it directly (with its own Pattern Sweep commit, since no separate committer role follows this one) when the cause is code-related, or escalating with a machine-readable environment/infrastructure marker when the cause is a container image, missing tool, or transient infra problem. Use whenever a CI check fails on a PR and the cause is not yet known.
---

# CI Failure Debugging

1. Read the full failure logs (`gh run view --log-failed`) and identify the root cause.
2. **Code-related cause**: fix it directly.
   - If the fix requires knowledge outside the instruction files, invoke Coding Researcher first; do not guess or fabricate. If Coding Researcher returns **Not possible**, escalate to the Orchestrator with the explanation.
   - Run a Pattern Sweep for the fixed construct and commit it after the fix (as a Pattern Sweep commit), since no Committer follows this role.
   - Apply IDE MCP code analysis to the fixed files (see the ide-mcp-code-analysis skill).
   - Before pushing a code fix, turn auto-merge off and convert the PR to draft, because GitHub could otherwise merge the fix as soon as its checks pass, before the AI Review Loop reviews it. Converting to draft alone is not enough, because GitHub does not turn auto-merge off when a PR becomes a draft. Convert with `gh pr ready <number> --repo <owner/repo> --undo`, and turn auto-merge off with `gh pr merge <number> --repo <owner/repo> --disable-auto` only when `gh pr view <number> --repo <owner/repo> --json autoMergeRequest --jq '.autoMergeRequest'` prints something other than `null`. A re-run needs neither, because it adds no commit.
3. **Cancelled required check**: it counts as failed. If nothing in the code caused the cancellation (a manual cancel or a runner shutdown), re-run it with `gh run rerun <run-id> --repo <owner/repo>` rather than pushing, because GitHub keeps the cancelled result on the head commit until the check runs again and the PR cannot merge until then. Report the re-run to the calling role as you would a pushed fix.
4. **Environmental or infrastructure cause**: escalate to the Orchestrator with a clear description, using the Environment/Infrastructure Block Marker below so the block can auto-clear once the fix ships.
5. After each pushed fix or re-run, post a one-line status comment on the PR naming each required check it addressed, using the check name exactly as `gh pr checks` reports it, in the form `### CI Debugger: <fix pushed|re-run started> for <check name>`. These comments are counted to cap rounds for one check, and a fixed form is what lets them be counted reliably.
6. A `### CI Debugger:` comment for a check counts towards that cap only when both of these hold:
   - Its author is the bot login or a trusted commenter (as for the `### AI Review Loop: reviewed` comment), because anyone else could post one and get the PR marked `Blocked` before a single fix attempt.
   - It was posted after the PR's latest `auto_merge_enabled` timeline event, or since the PR opened if there is none. Do not count from the latest `### AI Review Loop: reviewed` comment or `ready_for_review` event instead, because those are posted on every draft, fix, ready cycle, so the count would never reach the cap. Read the time with:

     ```bash
     gh api repos/<owner>/<repo>/issues/<number>/timeline --paginate --jq '.[] | select(.event == "auto_merge_enabled") | .created_at' | tail -n 1
     ```

7. Fix a pre-existing bug that causes the CI failure as part of the current work, including one the change merely exposes, because leaving it would keep the PR's required checks failing with nothing permitted to clear them. Report any other pre-existing bug found outside the current change's scope to the calling role (Orchestrator, or CI Monitor, which passes it on to the Orchestrator) rather than fixing it.

## Environment/Infrastructure Block Marker (MANDATORY, PRs only)

When a Blocked-ing failure is diagnosed as an environment/infrastructure problem, such as a bug in the container image, a missing tool, or a transient infra issue, rather than a bug in the PR's own code, add a machine-readable marker alongside the diagnosis so `oneshot` can auto-clear `Blocked` once the fix has actually shipped, instead of the PR sitting blocked until a human happens to notice:

1. Post the full human-readable diagnosis as normal: root cause, evidence, and (if known) the fix needed.
2. Append a single trailer line to that same comment:

   ```text
   <!-- orchestrator:env-block image-sha=${IMAGE_SHA_DEVELOPMENT_AGENT} -->
   ```

   Read `IMAGE_SHA_DEVELOPMENT_AGENT` from your own container environment (the same value printed at session start as part of "Image layer provenance"); this records which image build was current when you made the diagnosis.
3. Apply the `Blocked` label: `gh pr edit <number> --repo <owner/repo> --add-label "Blocked"`. The accompanying comment must name the specific instruction that requires the stop (here, this environment/infrastructure block convention).
4. Use this marker **only** for a genuine environment/infrastructure diagnosis. `oneshot` auto-clears `Blocked` the moment it observes a differently-built agent image, with no further human involvement; marking a real code question or design decision this way would resume work before a human actually answered it.

This convention only applies to PRs (there is no container session, and therefore no image to diagnose against, before a PR/branch exists).
