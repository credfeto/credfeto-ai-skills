---
name: credfeto-numbering-conventions
description: Format assumption, open-question, and plan/procedure-step lists with the correct marker (lower-case alpha for assumptions, `Q`-prefixed for open questions, `P`-prefixed for plan/procedure steps), write them as bulleted labels rather than literal ordered-list markers in committed Markdown so nested content survives, and give any step referenced from another list or file a named HTML anchor instead of a positional reference. Use whenever producing this kind of list in an instruction file, an issue/PR comment (e.g. an `## Implementation Plan` comment), or live chat, or when writing or editing a cross-reference to a specific step.
---

# Numbering and Cross-Reference Conventions

Applies everywhere a list of this kind is produced: in instruction files, and in an issue/PR comment or live chat (for example an `## Implementation Plan` comment).

- **Assumptions**: a lower-case alpha sequence: `a.`, `b.`, `c.`, ...
- **Open questions**: a `Q`-prefixed numbered sequence: `Q1.`, `Q2.`, `Q3.`, ...
- **Plan/procedure steps**: a `P`-prefixed sequence: `P1.`, `P2.`, `P3.`, ... **Never `P0`.** If a list would otherwise need a zero-indexed step, renumber the whole list to start at `P1` and update every reference to the shifted numbers.
- **Encoding in committed Markdown files**: write `P`/`Q`/alpha steps as bullets with a bold label, not as literal ordered-list markers: `- **P1.** text`, not `1. text` or `P1. text`. A literal `1.`/`P1.` marker is parsed as a new list item by CommonMark, which detaches any nested bullets, fenced code blocks, or continuation paragraphs that were children of the previous item; the bullet form keeps them nested (indent nested content 2 spaces under a `-` marker, not 3). This does not apply to prose in live chat or an issue/PR comment, where plain `P1.`/`Q1.`/`a.` text is fine.

## Named Anchors for Cross-Referenced Steps

Never reference a step by its number from **another list or file**: a plain "step 2" or "item 4" breaks silently the next time that list is renumbered, and the reference lives far enough from its target that an editor renumbering one won't think to check the other. Instead, give the target step a named, invisible HTML anchor and link to it:

```markdown
- **P4.** <a id="phase-b-convergence"></a>Otherwise, judge convergence yourself from the PR's history of prior code-review comments...
```

Place the `<a id="...">` tag inline at the very start of the item's own text, never on its own line: a bare HTML block between list items terminates the list under CommonMark. Name the anchor after the step's content (`phase-b-convergence`), not its position (`phase-b-p4`), so the link survives future renumbering. Reference it from elsewhere as a normal Markdown link to the anchor. If the target repository's Markdown linter flags raw `<a>` tags, add an appropriate lint override for this exact purpose rather than dropping the anchor.

A step referring to a **sibling step within its own list** (for example "return to P2", "once P4 is clean, go to P5") does not need an anchor: renumbering that list is a single, self-contained edit, and its own internal references get fixed as part of the same edit, so there's no separate file or list left stale. Only add an anchor once the reference crosses to different content that could be edited independently.
