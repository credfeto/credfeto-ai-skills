---
name: credfeto-ide-mcp-code-analysis
description: Best-effort use any configured and connected MCP IDE integration (e.g. Rider for .NET, WebStorm for TypeScript/JavaScript) to confirm changed files are clean of compiler and analyzer errors and warnings, additive to the language's own build/analyzer checks, skipping silently when no MCP is configured or a configured one fails to connect, and naming the gap in a PR comment when that happens. Use whenever writing, fixing, or reviewing code, including as part of a build/test verification step or a simplify, code-review, or security-review pass.
---

# IDE MCP Code Analysis

Whenever writing, fixing, or reviewing code, best-effort use any MCP IDE integration that is configured **and connected** for the modified files' language (e.g. Rider for .NET, WebStorm for TypeScript/JavaScript) to confirm those files are clean of compiler and analyzer errors and warnings. This is additive to the language's own build/analyzer checks (e.g. a .NET build-check tool run); it never replaces them.

## Rules (MANDATORY)

- **Best-effort, not blocking**: if no MCP is configured for the language, or a configured one fails to connect, skip this check for that step and continue with the language's normal build/analyzer tooling.
- **Report the gap on a PR**: if working on a PR, comment on it naming the tool and why it was unavailable (not configured, or configured but failed to connect), so a human can see the gap. Never add a `Blocked` label for this alone.
- **Applies to every code-touching step**: implementing, fixing, testing/verifying, and reviewing code, and to a simplify, code-review, or security-review pass over a diff.

## When to Run It

Apply it to the files just written, fixed, tested, or reviewed, alongside (not instead of) the language's own build and analyzer tooling:

- After writing or changing production code or tests.
- After fixing a bug or addressing a review comment.
- While verifying a change (build/test step) before handing off for review.
- During a code-review, security-review, or repository audit pass, against the files in scope for that pass.
