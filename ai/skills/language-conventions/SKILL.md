---
name: credfeto-language-conventions
description: Apply UK English to prose (documentation, comments, commit messages, AI instruction files), keep code identifiers in the platform or library's own convention rather than forcing UK spellings onto them, and never use em dash characters in any generated text. Use whenever writing or reviewing code, documentation, comments, or commit messages.
---

# Language Conventions

## English Variant

- All documentation, comments, and commit messages must be written in **UK English**.
- This includes prose in `README.md`, `CHANGELOG.md`, inline code comments, and AI instruction files.

## Code Identifiers

- Variable names, function names, class names, and other code identifiers should follow the **platform or library convention**, which is typically US English: do not force UK spellings onto them.
- For example, use `Color` not `Colour` when the platform or library defines it as `Color`; mixing conventions produces confusing and inconsistent code (e.g. `Color colour = Color.Red` is actively harmful).
- Where a library or platform uses a non-English language for its identifiers, use **English** for any variables or identifiers that interact with it.

## Punctuation

- Do not use em dash characters (`—`) in prose, comments, commit messages, or any generated text.
- Use a comma, colon, semicolon, or separate sentences instead, whichever best fits the sentence.
- The one exception is the backtick-quoted example of the character itself in this rule; it names the banned character rather than using it as punctuation, so do not "fix" it.
