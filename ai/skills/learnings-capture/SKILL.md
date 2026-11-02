---
name: credfeto-learnings-capture
description: Record a human-readable note in the knowledge-base MCP (the `kb_orchestrator` server) whenever a memory file (an AI instruction/rule file) is created or updated to record something learned during work. Use immediately alongside such a memory-file update, never as a replacement for it.
---

# Learnings Capture

Memory files (AI instruction/rule files) are terse, procedural text written for a model to follow, not for people. Whenever one is created or updated to record something learned during work, also record a human-readable note summarising it for people in the knowledge-base MCP (the `kb_orchestrator` server). Never copy rule wording verbatim into that note.

## Procedure (MANDATORY)

- **P1.** Write the note in plain prose: what was learned, why it mattered, and what prompted it.
- **P2.** Explain it as you would to a person unfamiliar with the AI rule files; do not restate instruction-file rule syntax.
- **P3.** Add it with the knowledge-base MCP server's tool for adding a note, titled `learning: <description>`, after searching the knowledge base for an existing note on the same thing and updating that one instead if there is one; see the note template below. If the server is not connected, put the note text in your hand-off or final report instead, so it is not lost.
- **P4.** Note the note's title in the commit message that updates the memory file.
- **P5.** This is additional to, not a replacement for, the memory-file update itself.

## Note Template

Add it with the knowledge-base MCP server's (`kb_orchestrator`) note tool, using this title and body:

```text
Title: learning: <short, human-readable description of what was learned>

**Context**: <repo and task where this came up>

**What we learned**: <plain-language explanation, no rule-file syntax>

**Why it matters**: <impact; what it prevents or improves going forward>
```
