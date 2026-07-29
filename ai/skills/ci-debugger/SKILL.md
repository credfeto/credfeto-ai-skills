---
name: credfeto-ci-debugger
description: Diagnose a failing CI check by reading its full logs and finding the root cause, fixing it directly when the cause is code-related, or escalating with a machine-readable environment/infrastructure marker when the cause is a container image, missing tool, or transient infra problem. Use whenever a CI check fails on a PR and the cause is not yet known.
---

# CI Failure Debugging

1. Read the full failure logs (e.g. `gh run view --log-failed`); do not diagnose from a truncated summary or the job status alone.
2. Identify the root cause.
3. **Code-related cause**: fix it directly.
   - If the fix requires knowledge outside the instruction files (unfamiliar API, complex library usage), research it first rather than guessing or fabricating a fix.
   - If research determines the fix is **not possible** as scoped, stop and escalate to a human with the explanation rather than partially applying a guess.
4. **Environmental or infrastructure cause** (a bug in the container image, a missing tool, a transient infra issue): escalate rather than attempting a workaround, using the Environment/Infrastructure Block Marker below so the block can auto-clear once the underlying fix actually ships.

## Environment/Infrastructure Block Marker (MANDATORY, PRs only)

When a failure is diagnosed as an environment/infrastructure problem rather than a bug in the PR's own code, add a machine-readable marker alongside the diagnosis so automation can auto-clear the block once the fix has actually shipped, instead of the PR sitting blocked until a human happens to notice:

1. Post the full human-readable diagnosis as normal: root cause, evidence, and (if known) the fix needed.
2. Append a single trailer line to that same comment, using whatever image/build identifier your execution environment exposes:

   ```text
   <!-- orchestrator:env-block image-sha=${IMAGE_SHA_DEVELOPMENT_AGENT} -->
   ```

   This records which image build was current when the diagnosis was made.
3. Apply the `Blocked` label: `gh pr edit <number> --repo <owner/repo> --add-label "Blocked"`.
4. Use this marker **only** for a genuine environment/infrastructure diagnosis. Automation auto-clears `Blocked` the moment it observes a differently-built execution image, with no further human involvement; marking a real code question or design decision this way would resume work before a human actually answered it.

This marker only applies to PRs; there is no environment session, and therefore no image to diagnose against, before a PR/branch exists.
