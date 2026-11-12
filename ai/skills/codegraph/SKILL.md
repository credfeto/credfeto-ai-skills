---
name: credfeto-codegraph
description: Locates and understands code through the CodeGraph `codegraph_explore` MCP tool before falling back to grep, find or reading files, in any repository whose root has a `.codegraph/` directory, and never through the `codegraph` CLI. Use whenever about to search for, locate or read code to understand it, including the call paths between symbols.
---

# CodeGraph

This skill covers how to use CodeGraph, a code index, to locate and understand code.

## No Index, No CodeGraph (MANDATORY)

- If the repository root has a `.codegraph/` directory, the repository is indexed by CodeGraph:
  follow the rest of this skill.
- If there is no `.codegraph/` directory, skip CodeGraph entirely and use the other tools as
  normal. In the agent container the index is built automatically; on a workstation, whether to
  index a repository is the user's decision.

## Use CodeGraph First When Indexed (MANDATORY)

In an indexed repository, call the `codegraph_explore` MCP tool
before grep/find or reading files whenever you need to locate or understand code:

- It returns the relevant symbols' verbatim source plus the call paths between them, including
  dynamic-dispatch hops that grep cannot follow.
- Name a file or symbol in the query to read its current line-numbered source.
- If the tool is listed but deferred, load it by name via tool search, then call it.

## MCP Tool Only (MANDATORY)

Use only the `codegraph_explore` MCP tool. Never run the `codegraph` command line, and never
offer it as a shell fallback: the agent container denies it.

## Index Lag

The index may lag an edit made moments earlier by a couple of seconds. If a result looks stale,
query again or read the file directly.
