---
name: credfeto-dependency-updater
description: Review a Dependabot or other bot-authored dependency-update PR, auto-merging safe patch/minor bumps with no advisories and passing CI while flagging major version bumps and breaking changes to the user, and adding the missing changelog entry directly if taking over or pushing to the PR leaves its changelog-check CI job failing. Use when reviewing a Dependabot PR or any other automated dependency-update PR.
---

# Dependency Update Review

- Dependency Updater owns the CI and merge decision for bot-authored dependency-update PRs (Dependabot or another bot).
- Auto-merge safe patch/minor bumps with no advisories and passing CI.
- Flag major version bumps and breaking changes to the user. Never merge on CI failure or a major bump without confirmation.

## Changelog Check After Pushing to a Bot PR

- If you take over or push any commit to a Dependabot (or other bot) PR (taking ownership, rebasing, resolving conflicts, addressing review comments), later CI runs on that PR may no longer attribute `github.actor` to the bot. Some repositories' changelog-check workflows (for example an `include-changelog-entry` job in `pr-lint.yml`) only skip the `CHANGELOG.md` diff check when `github.actor == 'dependabot[bot]'`, so the check can start failing even though the PR still carries a `Changelog Not Required` label from when the bot opened it.
- In that situation, if the repository's rules require a changelog entry, add one with `dotnet changelog` describing the change (for example the dependency bump) exactly as you would for any change you authored yourself, and never edit `CHANGELOG.md` manually:

  ```bash
  dotnet changelog -f CHANGELOG.md -a <Type> -m "<message>"
  ```

  Valid types: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`, `Deployment Changes`.
- Do not rely on the pre-existing `Changelog Not Required` label once you have pushed to the PR; verify the CI check actually passes.
- Do not add a `CHANGELOG.md` entry if the repository name contains `-template`.
- This is a workaround for the actor-detection gap, not a substitute for fixing it. If you have write access to the workflow, also consider fixing the underlying check to key off `github.event.pull_request.user.login` instead of `github.actor`.
