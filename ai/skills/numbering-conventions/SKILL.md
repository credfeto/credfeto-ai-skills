---
name: credfeto-numbering-conventions
description: Format assumption, open-question, and plan/procedure-step lists with the correct marker (lower-case alpha for assumptions, `Q`-prefixed for open questions, `P`-prefixed for plan/procedure steps), keep numbers counting up within a work item rather than restarting, write them as bulleted labels rather than literal ordered-list markers in committed Markdown so nested content survives, and give any step referenced from another list or file a named HTML anchor instead of a positional reference. Use whenever producing this kind of list in an instruction file, an issue/PR comment (e.g. an `## Implementation Plan` comment), or live chat, or when writing or editing a cross-reference to a specific step.
---

# Numbering and Cross-Reference Conventions

Applies everywhere a list of this kind is produced: in instruction files, and in an issue/PR comment or live chat (for example an `## Implementation Plan` comment).

- **Assumptions**: a lower-case alpha sequence: `a.`, `b.`, `c.`, ...
- **Open questions**: a `Q`-prefixed numbered sequence: `Q1.`, `Q2.`, `Q3.`, ...
- **Plan/procedure steps**: a `P`-prefixed sequence: `P1.`, `P2.`, `P3.`, ... **Never `P0`.** If a list would otherwise need a zero-indexed step, renumber the whole list to start at `P1` and update every reference to the shifted numbers.
- **Encoding in committed Markdown files**: write `P`/`Q`/alpha steps as bullets with a bold label, not as literal ordered-list markers: `- **P1.** text`, not `1. text` or `P1. text`. A literal `1.`/`P1.` marker is parsed as a new list item by CommonMark, which detaches any nested bullets, fenced code blocks, or continuation paragraphs that were children of the previous item; the bullet form keeps them nested (indent nested content 2 spaces under a `-` marker, not 3). This does not apply to prose in live chat or an issue/PR comment, where plain `P1.`/`Q1.`/`a.` text is fine.
- **CI enforcement**: an AI-instructions lint workflow fails a PR that starts a list item with a literal numbered marker in the global instruction files or `.ai-instructions`, and one that leaves a named anchor under `ai/` with no incoming link or a `#fragment` link with no matching heading or anchor. Fix the Markdown rather than working around the check, because both faults break silently otherwise.

## Numbers Are Never Reused

Within one work item, every numbering scheme keeps counting up and is never restarted: `Q` questions, alpha assumptions, `P` plan steps, and any other numbered list in live chat or an issue or PR comment. A number then names exactly one item for the life of the work item, so a later answer or reference such as "re Q3" can only mean one thing.

- A work item spans its issue and its PR, so the PR's first question continues from the last one asked on the issue: if the issue asked `Q1` to `Q6`, the PR starts at `Q7`.
- A revised or follow-up plan continues the numbering of the plan it supersedes rather than starting again.
- Alpha assumptions run on past `z.` to `aa.`, `ab.` and so on.
- Find the next free number by scanning the work item's issue and PR comments, and the conversation, for the highest number used so far in that scheme.
- Committed instruction files with self-contained procedures are unaffected and number each list from `P1`, because each list is read on its own and references into it from elsewhere use named anchors, not numbers.
- Numbers need not be unique across unrelated work items.

For example, an issue's plan asks `Q1` to `Q3` and lists assumptions `a.` and `b.`. A later batch of questions in chat starts at `Q4`, a revised plan's first new assumption is `c.`, and the first question on the PR continues from the highest `Q` used so far.

## Named Anchors for Cross-Referenced Steps

Never reference a step by its number from **another list or file**: a plain "step 2" or "item 4" breaks silently the next time that list is renumbered, and the reference lives far enough from its target that an editor renumbering one won't think to check the other. Instead, give the target step a named, invisible HTML anchor and link to it:

```markdown
- **P4.** <a id="phase-b-convergence"></a>Otherwise, judge convergence yourself from the PR's history of prior code-review comments...
```

Place the `<a id="...">` tag inline at the very start of the item's own text, never on its own line: a bare HTML block between list items terminates the list under CommonMark. Name the anchor after the step's content (`phase-b-convergence`), not its position (`phase-b-p4`), so the link survives future renumbering. Reference it from elsewhere as a normal Markdown link to the anchor, for example `[Phase B's P4](agent-roles.instructions.md#phase-b-convergence)`. The repository's `.markdownlint.json` allows `<a>` through an MD033 override for exactly this purpose.

A step referring to a **sibling step within its own list** (for example "return to P2", "once P4 is clean, go to P5") does not need an anchor: renumbering that list is a single, self-contained edit, and its own internal references get fixed as part of the same edit, so there's no separate file or list left stale. Only add an anchor once the reference crosses to different content that could be edited independently.
