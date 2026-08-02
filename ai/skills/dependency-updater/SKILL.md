---
name: credfeto-dependency-updater
description: Review a Dependabot or other bot-authored dependency-update PR, auto-merging safe patch/minor bumps with no advisories and passing CI while flagging major version bumps and breaking changes to a human, and fixing the changelog entry directly if taking ownership of the PR breaks its changelog-check CI job. Use when reviewing a Dependabot PR or any other automated dependency-update PR.
---

# Dependency Update Review

- Auto-merge safe patch/minor bumps: no known security advisories against either version, and CI passing.
- Flag major version bumps and any bump with a noted breaking change to a human for confirmation; never auto-merge these.
- Never merge on CI failure, and never merge a major version bump without explicit human confirmation.
- If you take over or push any commit to a Dependabot (or other bot) PR and its changelog-check CI job then fails, do not assume the bot's `Changelog Not Required` label still applies once you have pushed to the PR: add the missing changelog entry yourself using `dotnet changelog -f CHANGELOG.md -a <Type> -m "<message>"`, describing the dependency bump, exactly as you would for a change you authored yourself, and verify the CI check actually passes afterwards. Skip this step entirely if the repo does not keep a changelog at all (e.g. its name contains `-template`).
