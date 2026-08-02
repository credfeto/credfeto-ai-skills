---
name: credfeto-code-style
description: Write production code with well-chosen names instead of doc comments, only "why" inline comments, cyclomatic complexity kept below 20, weak (static) connascence preferred over strong (dynamic) forms, and immutable objects wherever possible. Use whenever writing or reviewing production code in any language.
---

# Code Style

## Code Comments (MANDATORY)

- **Never write XMLDoc (`///`) or Javadoc (`/** */`) comments.** Code must speak for itself through well-chosen names and clear structure.
- If a doc comment feels needed to explain what something does, that is a signal the code is too complex or the names are wrong: fix the code, not the documentation.
- The only acceptable inline comments explain a non-obvious **why**: a hidden constraint, a subtle invariant, a deliberate workaround for a known bug. If removing the comment would not confuse a future reader, do not write it.
- Do not write comments that describe what the code does; well-named identifiers already do that.
- Do not reference the current task, issue, PR, or caller in comments; those belong in the commit message or PR description and rot as the codebase evolves.

## Code Complexity

- Prefer clean code: readable, well-named, single-responsibility.
- Cyclomatic complexity must stay below 20 per method; refactor if it exceeds this.
- Keep cognitive complexity low; if a method is hard to read at a glance, simplify it.
- Prefer weak (static) connascence (Name, Type, Meaning) over strong (dynamic) forms (Execution, Timing, Identity); see [connascence.io](https://connascence.io/).
- Where stronger connascence is unavoidable, keep it local (within a single method or class).

## Immutability

Prefer immutable objects wherever possible, especially in async and multi-threaded code. Only break this for performance reasons when explicitly requested; note the reason in a comment.
