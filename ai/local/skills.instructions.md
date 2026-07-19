# Skills Instructions

[Back to Local Instructions Index](index.md)

Load this file when creating, updating, or removing skills in [ai/skills](../skills/).

## What Skills Are

Skills are self-contained, procedural extracts of the instruction files in [ai/global](../global/index.md) (and, where relevant, [ai/local](index.md)). Each skill packages one repeatable workflow (e.g. collecting coverage, committing, changelog management) in the Claude Code skill format so it can be installed and auto-discovered outside this repository.

## Layout and Naming

- Each skill lives in `ai/skills/<skill>/SKILL.md`.
- `SKILL.md` must start with YAML frontmatter containing exactly:
  - `name: credfeto-<skill>` — must match the installed folder name (lowercase letters, numbers, and hyphens only).
  - `description:` — third person, one paragraph, stating **what the skill does** and **when to use it** (the trigger conditions). This is the only text the model sees when deciding whether to load the skill, so triggers matter more than detail.
- Supporting files (scripts, templates) may sit alongside `SKILL.md` in the same folder and are installed with it.
- [install.sh](../skills/install.sh) installs every folder containing a `SKILL.md` into `~/.claude/skills/credfeto-<skill>`. It discovers skills automatically — adding a new skill requires no installer change.

## Generation Rules

1. **Skills are generated from instruction files — the instruction files are the source of truth.** Never invent rules in a skill that do not exist in an instruction file; if a rule is missing, add it to the instruction file first (following the source routing rules in `ai/global/task-workflow.instructions.md`), then regenerate the skill.
2. **Skills must be self-contained.** They are installed to `~/.claude/skills`, outside any repository, so they must not contain repo-relative links to `ai/global` or `ai/local` files. Inline everything the skill needs, including any helper scripts (e.g. the git identity check).
3. **Extract procedures, not categories.** A skill is a workflow with a clear trigger ("about to commit", "collecting coverage"), not a dump of a whole instruction file. One instruction file may feed several skills; one skill may draw from several instruction files.
4. **Keep MANDATORY markers and never-do rules verbatim in intent.** Wording may be adapted for the skill context, but no rule may be weakened, dropped, or contradicted.
5. All prose must be UK English, consistent with `ai/global/language.instructions.md`.
6. Shell scripts in `ai/skills` must follow `ai/global/shell-scripts.instructions.md` — `#!/bin/sh` preferred, `shellcheck` and `checkbashisms` clean, and the `die`/`success`/`info` output helpers.

## Update Rules

- **When a source instruction file changes, update the affected skills in the same branch** — treat a stale skill the same as failing CI. Use the registry below to find which skills are affected.
- **When adding or removing a skill**, update the registry below and re-run `ai/skills/install.sh` locally to verify installation.
- When reviewing skills, diff them against their source instruction files; if a skill and its source disagree, the instruction file wins — regenerate the skill.
- Skill changes follow the normal rules: commit on a branch (never `main`), conventional commit message, push after every commit. Skill changes **do** get changelog entries — see [changelog.instructions.md](changelog.instructions.md), which overrides the global AI-instruction-files skip rule for this repository.

## Skill Registry

| Skill | Installed as | Source instruction files |
| --- | --- | --- |
| [pre-work-healthcheck](../skills/pre-work-healthcheck/SKILL.md) | `credfeto-pre-work-healthcheck` | `git.instructions.md`, `git-rebasing.instructions.md`, `dotnet.instructions.md`, `task-workflow.instructions.md` |
| [changelog](../skills/changelog/SKILL.md) | `credfeto-changelog` | `changelog.instructions.md`, `dotnet.instructions.md` |
| [dotnet-coverage](../skills/dotnet-coverage/SKILL.md) | `credfeto-dotnet-coverage` | `dotnet.instructions.md`, `task-workflow.instructions.md`, `code-quality.instructions.md` |
| [dotnet-publish](../skills/dotnet-publish/SKILL.md) | `credfeto-dotnet-publish` | `dotnet.instructions.md` |
| [dotnet-test-patterns](../skills/dotnet-test-patterns/SKILL.md) | `credfeto-dotnet-test-patterns` | `dotnet.instructions.md`, `dotnet.examples.md`, `code-quality.instructions.md` |
| [dotnet-owned-packages](../skills/dotnet-owned-packages/SKILL.md) | `credfeto-dotnet-owned-packages` | `dotnet-owned-packages.instructions.md` |
| [git-commit](../skills/git-commit/SKILL.md) | `credfeto-git-commit` | `git.instructions.md`, `git-commits.instructions.md`, `git.examples.md`, `language.instructions.md`, `task-workflow.instructions.md` |
| [git-branch](../skills/git-branch/SKILL.md) | `credfeto-git-branch` | `git.instructions.md`, `git-rebasing.instructions.md`, `task-workflow.instructions.md`, `agent-roles.instructions.md` |
| [git-rebase](../skills/git-rebase/SKILL.md) | `credfeto-git-rebase` | `git-rebasing.instructions.md` |
| [pr-sync](../skills/pr-sync/SKILL.md) | `credfeto-pr-sync` | `task-workflow.instructions.md`, `git.instructions.md`, `github-cli.instructions.md`, `agent-roles.instructions.md` |
| [github-issue](../skills/github-issue/SKILL.md) | `credfeto-github-issue` | `git.instructions.md`, `task-workflow.instructions.md`, `github-cli.instructions.md`, `agent-roles.instructions.md` |
| [github-workflows](../skills/github-workflows/SKILL.md) | `credfeto-github-workflows` | `github-workflows.instructions.md`, `github-workflows.examples.md` |
| [shell-scripts](../skills/shell-scripts/SKILL.md) | `credfeto-shell-scripts` | `shell-scripts.instructions.md`, `shell-scripts.examples.md` |
| [firewall-rules](../skills/firewall-rules/SKILL.md) | `credfeto-firewall-rules` | `shell.firewall.instructions.md`, `shell.firewall.examples.md` |
| [sql-schema-change](../skills/sql-schema-change/SKILL.md) | `credfeto-sql-schema-change` | `sql.instructions.md`, `sql.examples.md` |
| [npm-packages](../skills/npm-packages/SKILL.md) | `credfeto-npm-packages` | `npm.instructions.md`, `git.instructions.md`, `git-rebasing.instructions.md`, `packages.instructions.md` |
| [performance-benchmarking](../skills/performance-benchmarking/SKILL.md) | `credfeto-performance-benchmarking` | `performance.instructions.md`, `dotnet.instructions.md` |
| [docker](../skills/docker/SKILL.md) | `credfeto-docker` | `docker.instructions.md` |
| [docker-rootless-podman-systemd](../skills/docker-rootless-podman-systemd/SKILL.md) | `credfeto-docker-rootless-podman-systemd` | `docker-rootless-podman-systemd.instructions.md` |
| [readme-documentation](../skills/readme-documentation/SKILL.md) | `credfeto-readme-documentation` | `documentation.instructions.md` |
| [deprecation-handling](../skills/deprecation-handling/SKILL.md) | `credfeto-deprecation-handling` | `code-quality.instructions.md` |
| [secure-coding](../skills/secure-coding/SKILL.md) | `credfeto-secure-coding` | `security.instructions.md` |
| [error-handling](../skills/error-handling/SKILL.md) | `credfeto-error-handling` | `error-handling.instructions.md` |
| [structured-logging](../skills/structured-logging/SKILL.md) | `credfeto-structured-logging` | `logging.instructions.md` |
| [api-http-tests](../skills/api-http-tests/SKILL.md) | `credfeto-api-http-tests` | `api.instructions.md` |
| [gitignore-management](../skills/gitignore-management/SKILL.md) | `credfeto-gitignore-management` | `gitignore.instructions.md` |
| [dependency-selection](../skills/dependency-selection/SKILL.md) | `credfeto-dependency-selection` | `packages.instructions.md`, `git.instructions.md`, `git-rebasing.instructions.md` |

## Installation

```bash
./ai/skills/install.sh
```

Installs (or reinstalls, replacing any previous copy) every skill into `~/.claude/skills/credfeto-<skill>`.

## Automated Reconciliation

The [reconcile-skills workflow](../../.github/workflows/reconcile-skills.yml) runs every Sunday and reconciles **all** skills against the current instruction files (not just recent diffs — reconciliation is idempotent and self-healing). It regenerates stale skills, creates newly qualifying ones, removes orphaned ones, updates the registry, adds changelog entries, and pushes the result directly to `main` — an owner-sanctioned exception to the never-commit-to-`main` rule, chosen for transparency. It requires the `CLAUDE_CODE_OAUTH_TOKEN` repository secret; setup steps are documented in comments at the top of the workflow file.
