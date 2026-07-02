# credfeto-ai-skills

Installable [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skills generated from the shared AI instruction files in [ai/global](ai/global/index.md) and [ai/local](ai/local/index.md).

## Skills

Each skill is a self-contained, procedural workflow extracted from the instruction files (which remain the source of truth):

| Skill | Covers |
| --- | --- |
| [pre-work-healthcheck](ai/skills/pre-work-healthcheck/SKILL.md) | Prerequisites, pre-commit baseline, `dotnet buildcheck`, existing-work check |
| [changelog](ai/skills/changelog/SKILL.md) | `dotnet changelog` usage, entry content, skip rules |
| [dotnet-coverage](ai/skills/dotnet-coverage/SKILL.md) | Test project identification, coverage collection, per-assembly reports |
| [dotnet-publish](ai/skills/dotnet-publish/SKILL.md) | Staged trimming then AOT publishing workflow |
| [git-commit](ai/skills/git-commit/SKILL.md) | Identity/GPG checks, commit rules, Conventional Commits, push cadence |
| [git-branch](ai/skills/git-branch/SKILL.md) | Branching, naming, rebasing, version-conflict resolution |
| [pr-sync](ai/skills/pr-sync/SKILL.md) | PR title/body/label sync, lifecycle, bot-created PR ownership |
| [github-issue](ai/skills/github-issue/SKILL.md) | Issue creation flow, labels, multi-component task tracking |

See [ai/local/skills.instructions.md](ai/local/skills.instructions.md) for the skill format, generation rules, and registry.

## Installation

```bash
./ai/skills/install.sh
```

Installs every skill into `~/.claude/skills` as `credfeto-<skill>`, replacing any previous copy. New Claude Code sessions discover them automatically.

## Automated Reconciliation

The [reconcile-skills workflow](.github/workflows/reconcile-skills.yml) runs every Sunday, reconciling all skills against the current instruction files and pushing any changes to `main`. Setup requirements are documented in comments at the top of the workflow file.

## Changelog

View [changelog][changelog].

## Contributing

See [contributing guidelines][contributing].

## Security

See [security policy][security].

## Licence

This project is licensed under the [MIT Licence][licence].

[changelog]: CHANGELOG.md
[contributing]: CONTRIBUTING.md
[licence]: LICENSE
[security]: SECURITY.md
