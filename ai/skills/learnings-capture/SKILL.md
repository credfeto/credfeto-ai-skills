---
name: credfeto-learnings-capture
description: Record a human-readable note in the knowledge-base MCP (the `kb` server, tools `mcp__kb__*`) whenever a memory file (an AI instruction/rule file) is created or updated to record something learned during work, and search and record tooling fixes there. Use immediately alongside such a memory-file update, never as a replacement for it, and before blocking for a human on, or after working around, a build, SDK, analyzer or hook problem.
---

# Learnings Capture

Memory files (AI instruction/rule files) are terse, procedural text written for a model to follow, not for people. Whenever one is created or updated to record something learned during work, also record a human-readable note summarising it for people in the knowledge-base MCP (the `kb` server, tools `mcp__kb__*`). Never copy rule wording verbatim into that note.

## Procedure (MANDATORY)

- **P1.** Write the note in plain prose: what was learned, why it mattered, and what prompted it.
- **P2.** Explain it as you would to a person unfamiliar with the AI rule files; do not restate instruction-file rule syntax.
- **P3.** Add it with the knowledge-base MCP server's tool for adding a note, titled `learning: <description>`, after searching the knowledge base for an existing note on the same thing and updating that one instead if there is one; see the note template below. If the server is not connected, put the note text in your hand-off or final report instead, so it is not lost.
- **P4.** Note the note's title in the commit message that updates the memory file.
- **P5.** This is additional to, not a replacement for, the memory-file update itself.

## Note Template

Add it with the knowledge-base MCP server's (`kb`, tools `mcp__kb__*`) note tool, using this title and body:

```text
Title: learning: <short, human-readable description of what was learned>

**Context**: <repo and task where this came up>

**What we learned**: <plain-language explanation, no rule-file syntax>

**Why it matters**: <impact; what it prevents or improves going forward>
```

## Tooling Problems: Read Before Blocking, Write After Solving (MANDATORY)

Tooling and build fixes are recorded in the knowledge-base MCP (the `kb` server, tools `mcp__kb__*`) so that every agent finds them without searching other repositories' code. A tooling problem is a build, SDK, analyzer, hook or similar problem that is not specific to one repository, not a genuine design question.

- **P1.** Before blocking for a human on a tooling problem, search the knowledge base for the error text, the project type and the setting involved. If a recorded fix applies, use it and cite the note in the PR, because a fix that already exists makes a human block needless.
- **P2.** When you work around a tooling problem that is not specific to one repository (an SDK incompatibility, an analyzer conflict, a hook quirk), add a short knowledge-base note with the symptom, the exact fix and why it works, using the tooling note template below, after searching for an existing note on the same thing and updating that one instead if there is one, so the next agent finds the fix without looking at other repositories. If the server is not connected, put the note text in your hand-off or final report instead.
- **P3.** Block only when no recorded fix applies, and list the searches made in the block comment, because the human can then see what was already tried.

## Tooling Note Template

Add it with the knowledge-base MCP server's (`kb`, tools `mcp__kb__*`) note tool, using this title and body:

```text
Title: tooling: <short description of the symptom>

**Symptom**: <exact error text, project type, SDK or tool version>

**Fix**: <the exact change, command or setting>

**Why it works**: <the cause and why the fix addresses it>

**Found in**: <repo and PR where it was first applied>
```
