---
name: credfeto-gitignore-management
description: Maintain .gitignore files correctly — never commit IDE-specific files, treat the root .gitignore as owned by credfeto/cs-template, and add repo-specific entries at the right directory level. Use whenever creating or modifying any .gitignore file.
---

# .gitignore Management

## IDE Files

Never commit IDE-specific files or folders, including:

- `.idea/` — JetBrains IDEs
- `.vscode/` — Visual Studio Code
- `.vs/` — Visual Studio

These belong in the root `.gitignore`.

## Root `.gitignore`

The root `.gitignore` is the global baseline, owned by `credfeto/cs-template`:

- Only edit the root `.gitignore` directly in `credfeto/cs-template`. In any other repository, treat it as distributed via the standard template update mechanism.
- If an IDE exclusion or other baseline entry is missing from the root `.gitignore` in a non-template repository, raise the gap in `credfeto/cs-template` rather than adding it locally.

## Additional `.gitignore` Files

Derived repositories may add `.gitignore` files for repo-specific concerns (language build output, generated content, local tooling artefacts), placed at the appropriate directory level (e.g. a nested `.gitignore` inside a subproject that has its own generated-output pattern).

## Consistency

When creating or modifying any `.gitignore`, check it against the root `.gitignore` to ensure no duplication or conflicts.
