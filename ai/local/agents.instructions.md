# Agents Instructions

[Back to Local Instructions Index](index.md)

Load this file when creating, updating, or removing agent definitions in [ai/agents](../agents/).

## What Agents Are

Agents are Claude Code custom agent definitions, one per named role in `ai/global/agent-roles.instructions.md` (plus one per Code Reviewer lens). Each packages a role's responsibilities, inputs, outputs and hand-offs so the role can be invoked through the `Agent` tool outside this repository. The procedural detail a role needs lives in the skills it preloads (see [skills.instructions.md](skills.instructions.md)); an agent is the role's identity and contract, not a copy of its skills.

## Layout and Naming

- Each agent lives in `ai/agents/<slug>/AGENT.md`, where `<slug>` is a key in [config.yaml](../agents/config.yaml).
- [config.yaml](../agents/config.yaml) is authoritative for every agent's frontmatter: `model`, `tools` and `skills`. Each entry also has a `name:` field holding the role's source heading in `agent-roles.instructions.md`; it is for traceability only and never appears in generated frontmatter. A `default:` block supplies values for any field an entry omits, and for a role that has no entry.
- `AGENT.md` must start with YAML frontmatter containing exactly, in this order:
  - `name: credfeto-<slug>`: lowercase letters, numbers and hyphens only; never a colon.
  - `description:`: third person, one paragraph, stating **what the agent does** and **when to invoke it**. This is the text the invoking session uses to choose the agent, so triggers matter more than detail.
  - `model:`: the entry's `model` from `config.yaml`. Valid values are `sonnet`, `opus`, `haiku`, `fable`, `inherit` or a full model ID; `opusplan` is a main-session setting only and is not valid for an agent.
  - `tools:`: the entry's `tools` from `config.yaml`, as a comma-separated string.
  - `skills:`: the entry's `skills` from `config.yaml` as a block list; omitted when the list is empty. Preloaded skills are injected in full at agent startup, so list only the skills the role cannot work without; every agent also has the `Skill` tool to load others on demand.
- [install](../agents/install) installs every folder containing an `AGENT.md` as the single file `~/.claude/agents/credfeto-<slug>.md` (agents are flat files, not folders) and removes any installed `credfeto-*.md` agent that no longer has a source folder. It discovers agents automatically; adding an agent requires no installer change.

## Generation Rules

- **P1.** **Agents are generated from instruction files; the instruction files are the source of truth.** Sources are the role's section of `ai/global/agent-roles.instructions.md`, the rules in `ai/global/task-workflow.instructions.md` that apply to the role (for the lesser-model roles, Failure Handling: No Self-Repair), and the [Agent Contracts](#agent-contracts) below. Never invent rules in an agent.
- **P2.** **Agents must be self-contained.** They are installed outside any repository, so they must not contain repo-relative links to `ai/global` or `ai/local` files.
- **P3.** **Keep bodies thin.** State the role, who invokes it, its inputs, its key rules, its report contract and the agents it invokes, then direct it to its preloaded skill(s) for the full procedure. Do not duplicate skill content. The six Code Reviewer lens agents have no skill of their own, so their scope, Critical Instructions, Categories and report contract are inlined.
- **P4.** **Keep MANDATORY markers and never-do rules verbatim in intent.** Wording may be adapted, but no rule may be weakened, dropped or contradicted.
- **P5.** **An agent contains only what its sources state.** When a source stops requiring something, remove it and reword so the agent reads as if the requirement had never existed.
- **P6.** Never edit `config.yaml` while generating or reconciling agents; it changes only by a human-reviewed pull request. A role with no `config.yaml` entry is generated with the `default:` values until a human adds its entry.
- **P7.** All prose must be UK English, consistent with `ai/global/language.instructions.md`, and every `AGENT.md` must pass `markdownlint`.

## Agent Contracts

These rules govern how the generated agents work together. They apply in addition to `agent-roles.instructions.md`.

- **Invocation by installed name.** An agent that invokes another role does so through the `Agent` tool using the installed name (`credfeto-<slug>`), e.g. Orchestrator invokes `credfeto-code-writer`, and Code Writer, Code Fixer, Code Reviewer and CI Debugger invoke `credfeto-coding-researcher`.
- **Lens input.** Code Reviewer passes each lens agent the output of `git diff origin/main...HEAD` and the list of changed files in its prompt. Repo Auditor passes each lens agent the file list of the group being audited. Lens agents are read-only and review only what they were given, reading files for context as needed.
- **Lens report failures.** Code Reviewer and Repo Auditor treat a lens report that is missing, a refusal, or not valid JSON in the documented shape as a failure, never as clean: re-run that lens once, and if it fails again escalate to Orchestrator naming the lens. Only a valid `{"clean": true}` report counts as clean.

## Update Rules

- **When a source instruction file or `config.yaml` changes, update the affected agents in the same branch**; treat a stale agent the same as failing CI. Use the registry below to find which agents are affected.
- **When adding or removing an agent**, add or remove its `config.yaml` entry and registry row, and re-run `ai/agents/install` locally to verify installation. Removing an agent deletes its whole `ai/agents/<slug>/` folder; `config.yaml` and `install` are never removed with it.
- When reviewing agents, diff them against their sources; if an agent and its source disagree, the source wins: regenerate the agent.
- Agent changes follow the normal rules: commit on a branch (never `main`), conventional commit message, push after every commit, and a changelog entry per [changelog.instructions.md](changelog.instructions.md).

## Agent Registry

| Agent | Installed as | Source sections (`agent-roles.instructions.md` unless stated) |
| --- | --- | --- |
| [orchestrator](../agents/orchestrator/AGENT.md) | `credfeto-orchestrator` | Orchestrator; `task-workflow.instructions.md` Routing Rules |
| [coding-researcher](../agents/coding-researcher/AGENT.md) | `credfeto-coding-researcher` | Coding Researcher |
| [code-writer](../agents/code-writer/AGENT.md) | `credfeto-code-writer` | Code Writer |
| [code-tester](../agents/code-tester/AGENT.md) | `credfeto-code-tester` | Code Tester; `task-workflow.instructions.md` Failure Handling |
| [code-reviewer](../agents/code-reviewer/AGENT.md) | `credfeto-code-reviewer` | Code Reviewer; Agent Contracts |
| [code-reviewer-reuse](../agents/code-reviewer-reuse/AGENT.md) | `credfeto-code-reviewer-reuse` | Code Reviewer: Reuse; Agent Contracts |
| [code-reviewer-quality](../agents/code-reviewer-quality/AGENT.md) | `credfeto-code-reviewer-quality` | Code Reviewer: Quality; Agent Contracts |
| [code-reviewer-efficiency](../agents/code-reviewer-efficiency/AGENT.md) | `credfeto-code-reviewer-efficiency` | Code Reviewer: Efficiency; Agent Contracts |
| [code-reviewer-correctness](../agents/code-reviewer-correctness/AGENT.md) | `credfeto-code-reviewer-correctness` | Code Reviewer: Correctness; Agent Contracts |
| [code-reviewer-security](../agents/code-reviewer-security/AGENT.md) | `credfeto-code-reviewer-security` | Code Reviewer: Security; Agent Contracts |
| [code-reviewer-compliance](../agents/code-reviewer-compliance/AGENT.md) | `credfeto-code-reviewer-compliance` | Code Reviewer: Compliance; Agent Contracts |
| [repo-auditor](../agents/repo-auditor/AGENT.md) | `credfeto-repo-auditor` | Repo Auditor; Agent Contracts |
| [code-fixer](../agents/code-fixer/AGENT.md) | `credfeto-code-fixer` | Code Fixer |
| [rebase-agent](../agents/rebase-agent/AGENT.md) | `credfeto-rebase-agent` | Rebase Agent; `task-workflow.instructions.md` Failure Handling |
| [ci-debugger](../agents/ci-debugger/AGENT.md) | `credfeto-ci-debugger` | CI Debugger |
| [changelog](../agents/changelog/AGENT.md) | `credfeto-changelog` | Changelog; `task-workflow.instructions.md` Failure Handling |
| [committer](../agents/committer/AGENT.md) | `credfeto-committer` | Committer; `task-workflow.instructions.md` Failure Handling |
| [pr-submitter](../agents/pr-submitter/AGENT.md) | `credfeto-pr-submitter` | PR Submitter; `task-workflow.instructions.md` Failure Handling |
| [ci-monitor](../agents/ci-monitor/AGENT.md) | `credfeto-ci-monitor` | CI Monitor; `task-workflow.instructions.md` Failure Handling |
| [dependency-updater](../agents/dependency-updater/AGENT.md) | `credfeto-dependency-updater` | Dependency Updater |

## Installation

```bash
./ai/agents/install
```

Install skills first (`./ai/skills/install`): agents preload skills by their installed names.

## Automated Reconciliation

The [reconcile-agents workflow](../../.github/workflows/reconcile-agents.yml) runs every day and reconciles **all** agents against their sources and `config.yaml`. Like the skills workflow, it first mirrors `.ai-instructions` and `ai/global/` from `credfeto/cs-template`, then regenerates stale agents, creates agents for newly added roles, removes agents whose role no longer exists, updates the registry, adds changelog entries and pushes the result directly to `main`. The agent may only delete agent folders and may not modify `config.yaml` or `install`; later steps fail the run otherwise. It runs an hour after the skills workflow so the two never push to `main` at the same time, and uses the same `CLAUDE_CODE_OAUTH_TOKEN` and `SOURCE_PUSH_TOKEN` secrets.
