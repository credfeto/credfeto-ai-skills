---
name: credfeto-learnings-capture
description: File a human-readable issue in credfeto/credfeto-notes whenever a memory file (an AI instructions file, such as CLAUDE.md, or any repo instructions/rules file) is created or updated to record something learned during work. Use immediately alongside such a memory-file update, never as a replacement for it.
---

# Learnings Capture

Memory files (AI instruction/rule files) are terse, procedural text written for a model to follow, not for people. Whenever one is created or updated to record something learned during work, also file a human-readable issue in `credfeto/credfeto-notes` summarising it for people. Never copy rule wording verbatim into that issue.

## Procedure (MANDATORY)

1. Write the issue in plain prose: what was learned, why it mattered, and what prompted it.
2. Explain it as you would to a person unfamiliar with the AI rule files; do not restate instruction-file rule syntax.
3. Create the issue with `gh issue create --repo credfeto/credfeto-notes` and the `AI-Work` label; see the command template below.
4. Note the resulting issue URL in the commit message that updates the memory file.
5. This is additional to, not a replacement for, the memory-file update itself.

## Issue Command Template

```bash
gh issue create --repo credfeto/credfeto-notes \
  --title "<short, human-readable description of what was learned>" \
  --label "AI-Work" \
  --body "**Context**: <repo and task where this came up>

**What we learned**: <plain-language explanation, no rule-file syntax>

**Why it matters**: <impact; what it prevents or improves going forward>"
```
