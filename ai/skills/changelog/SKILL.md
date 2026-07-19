---
name: credfeto-changelog
description: Add or remove CHANGELOG.md entries using the dotnet changelog tool (Credfeto.Changelog.Cmd). Use whenever a change needs a changelog entry, before committing feature/fix work, or when acting as the Changelog agent. Never edit CHANGELOG.md by hand.
---

# Changelog Management

Manage `CHANGELOG.md` entries using `Credfeto.Changelog.Cmd`; **never edit `CHANGELOG.md` manually**.

`Credfeto.Changelog.Cmd` is the dotnet tool package that provides the `dotnet changelog` command; no separate install step is required if the repo's dotnet tool manifest already includes it. Always invoke it as `dotnet changelog`; never search for the binary or call it directly from `~/.dotnet/tools`.

## When to Skip

Do **not** add an entry if:

- The repository name contains `-template` (e.g. `credfeto/cs-template`), kept blank for template consumers.
- The change is documentation-only with no effect on production code.
- The change is to AI instruction files.

## Entry Content

Entries must describe **what changed and why it matters**, not how it was implemented.

## Commands

```bash
# Add an entry
dotnet changelog -f CHANGELOG.md -a <Type> -m "<message>"

# Remove an entry
dotnet changelog -f CHANGELOG.md -r <Type> -m "<exact message to remove>"

# Help
dotnet changelog --help
```

Valid types: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`, `Deployment Changes`

## Repository Requirements

- `CHANGELOG.md` must be listed in `.markdownlintignore` at the repo root (create the file if absent).
