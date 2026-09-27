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

## Agents

Each agent is a Claude Code custom agent definition for one role in the multi-agent pipeline (Orchestrator, Code Writer, Code Reviewer and its six review lenses, Committer, and so on), generated from the role definitions in the instruction files. [ai/agents/config.yaml](ai/agents/config.yaml) sets each agent's model, tools and preloaded skills.

See [ai/local/agents.instructions.md](ai/local/agents.instructions.md) for the agent format, generation rules, and registry.

## Installation

```bash
./install
```

Installs every skill into `~/.claude/skills` as `credfeto-<skill>` and then every agent into `~/.claude/agents` as `credfeto-<agent>.md`, replacing any previous copy. Skills go first because agents preload them by name. New Claude Code sessions discover both automatically. To install only one kind, run `./ai/skills/install` or `./ai/agents/install` directly.

## Automated Reconciliation

The [reconcile-skills workflow](.github/workflows/reconcile-skills.yml) and [reconcile-agents workflow](.github/workflows/reconcile-agents.yml) run every day, reconciling all skills and agents against the current instruction files and pushing any changes to `main`. Setup requirements are documented in comments at the top of the reconcile-skills workflow file.

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
