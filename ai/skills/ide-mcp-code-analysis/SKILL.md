---
name: credfeto-ide-mcp-code-analysis
description: Best-effort use any configured and connected MCP IDE integration (e.g. Rider for .NET, WebStorm for TypeScript/JavaScript) to confirm changed files are clean of compiler and analyzer errors and warnings, additive to the language's own build/analyzer checks, skipping the check when no MCP is configured or a configured one fails to connect, and naming the gap in a PR comment when working on a PR. Use whenever writing, fixing, or reviewing code, including during the simplify, code-review, and security-review phases of the PR review loop.
---

# IDE MCP Code Analysis

Whenever writing, fixing, or reviewing code, best-effort use any MCP IDE integration that is configured **and connected** for the modified files' language (e.g. Rider for .NET, WebStorm for TypeScript/JavaScript) to confirm those files are clean of compiler and analyzer errors and warnings. This is additive to the language's own build/analyzer checks (e.g. a .NET build-check tool run); it never replaces them.

## Rules (MANDATORY)

- **Best-effort, not blocking**: if no MCP is configured for the language, or a configured one fails to connect, skip this check for that step and continue with the language's normal build/analyzer tooling.
- **Report the gap on a PR**: if working on a PR, comment on it naming the tool and why it was unavailable (not configured, or configured but failed to connect), so a human can see the gap. Never add `Blocked` for this alone.
- **Applies to every code-touching role**: Code Writer, Code Fixer, Code Tester, Code Reviewer, CI Debugger, Repo Auditor, and Phases A-C (Simplify, Code Review, Security Review) of the PR Workflow AI Review Loop.
