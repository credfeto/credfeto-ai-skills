---
name: credfeto-dotnet-analyzer-conflicts
description: Resolve a conflict between two .NET analyzer diagnostics, where fixing one diagnostic raises another, using the pre-approved resolution table for known pairs (for example IDE0028 versus MA0002) and stopping to ask the repo owner, with an escalation issue and the Blocked label, for any pair not in the table. Use whenever fixing one .NET build or analyzer warning raises a different one, or whenever a suppression for one of two conflicting diagnostics is being considered.
---

# .NET Analyzer Diagnostic Conflicts

Two analyzers can disagree, so that fixing one diagnostic raises another. The table below records the pre-approved resolution for each known pair, so a pair that has already been decided is resolved the same way every time without asking again.

An entry in this table is the repo owner's explicit written permission for the suppression it names, for that diagnostic pair and that affected code only, in every repo that uses these instructions. It grants nothing wider: any other suppression of either diagnostic still needs its own permission, because suppressing a warning without explicit written permission from the repo owner is prohibited.

## Resolution Table

| Diagnostic A | Diagnostic B | Affected code | Resolution | Justification |
| --- | --- | --- | --- | --- |
| `IDE0028` (Collection initialization can be simplified) | `MA0002` (IEqualityComparer/IComparer is missing) | A collection constructed with an explicit `IEqualityComparer` or `IComparer` (for example `new Dictionary<string, int>(StringComparer.Ordinal)`) | Suppress `IDE0028` with `[SuppressMessage]` and the justification in the last column; keep the comparer | A collection expression cannot pass a comparer to the collection's constructor, so simplifying would silently drop it (for example `Ordinal`) and change lookup semantics |

The `IDE0028` entry is applied as:

```csharp
[SuppressMessage(
    category: "Style",
    checkId: "IDE0028: Collection initialization can be simplified",
    Justification = "A collection expression cannot pass a comparer to the collection's constructor, so simplifying would silently drop it (for example Ordinal) and change lookup semantics"
)]
```

## Unlisted Pairs

When two diagnostics conflict and the pair, for that kind of code, is not in the table:

- **P1.** Stop. Do not guess a resolution or suppress either diagnostic, because only the repo owner can grant permission to suppress.
- **P2.** Raise an issue in `credfeto/cs-template` describing the conflict: both diagnostic IDs, the affected code, and the candidate resolutions. Give it the content that a template rule escalation asks for (source repository, current behaviour or gap, proposed rule text, and the reason for template propagation), using this command:

  ```bash
  gh issue create --repo credfeto/cs-template \
    --title "<short description of the rule change>" \
    --label "AI-Work" \
    --body "**Source repository**: <repo where need was discovered>

  **Current behaviour / gap**: <what is missing or inconsistent>

  **Proposed rule text**: <concrete rule update or new instruction text>

  **Reason for template propagation**: <why this should apply across all repos>"
  ```

- **P3.** Add `Blocked` to the affected issue or PR (`gh issue edit <number> --repo <owner/repo> --add-label "Blocked"`, or `gh pr edit` for a PR) and wait for the repo owner's decision. Use only the `Blocked` label for this purpose. Do not continue working on the item until the label is removed. The accompanying comment must name the specific instruction that requires the stop (here, the unlisted pairs rule above). If a human answers in a live chat session rather than on GitHub, post the answer yourself as a comment, quoting the live instruction, before resuming work. Unlike a normal template rule escalation, work on the affected code does not carry on meanwhile, because the code cannot build while one of the two diagnostics stands.

## Adding an Entry

Once the repo owner has chosen a resolution, add the pair to the table, in the same PR or a follow-up, with every column filled in: both diagnostic IDs, the affected code, the resolution and the justification text. Every entry needs the repo owner's decision first, because an entry is itself the permission to suppress.
