---
name: credfeto-ide-mcp-code-analysis
description: Best-effort use any configured and connected MCP IDE integration (e.g. Rider for .NET, WebStorm for TypeScript/JavaScript, DataGrip for SQL) to confirm changed files are clean of compiler and analyzer errors and warnings, additive to the language's own build/analyzer checks, skipping the check when no MCP is configured or a configured one fails to connect, and naming the gap in a PR comment when working on a PR. Use whenever writing, fixing, or reviewing code, including during the simplify, code-review, and security-review phases of the PR review loop.
---

# IDE MCP Code Analysis

Whenever writing, fixing, or reviewing code, best-effort use any MCP IDE integration that is configured **and connected** for the modified files' language (e.g. Rider for .NET, WebStorm for TypeScript/JavaScript, DataGrip for SQL) to confirm those files are clean of compiler and analyzer errors and warnings. This is additive to the language's own build/analyzer checks (e.g. a .NET build-check tool run); it never replaces them.

## Rules (MANDATORY)

- **Best-effort, not blocking**: if no MCP is configured for the language, or a configured one fails to connect, skip this check for that step and continue with the language's normal build/analyzer tooling.
- **Report the gap on a PR**: if working on a PR, comment on it naming the tool and why it was unavailable (not configured, or configured but failed to connect), so a human can see the gap. Never add `Blocked` for this alone.
- **SQL**: this includes SQL embedded in another language's string literals (e.g. Dapper or ADO.NET queries in C#, which the host language's IDE MCP, such as Rider, checks rather than DataGrip). Ignore unresolved table, column and other object inspections, whatever their severity, that arise only because the IDE's data source does not match the branch's schema (none is attached, or it predates objects this branch's migration scripts create). Syntax errors in the repository's SQL dialect and every other inspection still count (ignore errors that come only from a wrong or unset dialect; where an IDE inspection conflicts with the repository's SQL linter, the linter wins), and every object name must still match the schema defined in the repository's migration scripts or DACPAC.
- **Applies to every code-touching role**: Code Writer, Code Fixer, Code Tester, Code Reviewer, CI Debugger, Repo Auditor, Orchestrator (only for the Phase B and C reviews it runs itself), and Phases A-C (Simplify, Code Review, Security Review) of the PR Workflow AI Review Loop.
