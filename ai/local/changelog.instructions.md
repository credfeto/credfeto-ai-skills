# Changelog Instructions (Local Override)

[Back to Local Instructions Index](index.md)

Load this file whenever making any change in this repository.

## Always Add a Changelog Entry (MANDATORY)

This repository contains only AI instructions and skills — its instruction and skill files **are** the product. The global skip rule in `ai/global/changelog.instructions.md` ("do not add an entry if the change is to AI instruction files") therefore **does not apply here** and is explicitly overridden:

- **Every change in this repository requires a changelog entry** — including changes to AI instruction files, skills, and the skill installer.
- The only remaining skip is a change that touches nothing but `CHANGELOG.md` itself.

All other global changelog rules still apply:

- Use `dotnet changelog` (`Credfeto.Changelog.Cmd`) — never edit `CHANGELOG.md` manually.
- Entries must describe what changed and why it matters — not how it was implemented.
- Valid types: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`, `Deployment Changes`.
