---
name: credfeto-deprecation-handling
description: Triage deprecation warnings seen in test output — fix ones caused by your change immediately, track pre-existing ones with a GitHub issue. Use whenever a deprecation warning (framework or runtime warning about a deprecated API) appears while running tests.
---

# Deprecation Warning Triage

When a deprecation warning appears in test output (framework or runtime warnings about deprecated APIs), do not suppress or ignore it — triage it using the rules below.

## 1. Warning Is New — Caused By Your Change

Fix the deprecation before committing; do not leave it for later.

## 2. Warning Is Pre-Existing — Not Caused By Your Change

1. Search for an existing open GitHub issue in the current repository covering the same warning — search for the deprecated API name, the warning text, and the affected component or dependency.
2. **If a matching open issue already exists**: update it with any new context found, or reference it in your work — do not create a duplicate issue.
3. **If no matching open issue exists**: raise a new GitHub issue in the current repository with:
   - A clear title describing the deprecated API.
   - The full warning text.
   - The component or dependency responsible.
   - What needs to be done to resolve it.
   - Label the issue `AI-Work`.

## Rule (MANDATORY)

Do not suppress or ignore deprecation warnings under any circumstances — every warning is either fixed immediately or tracked in an issue.
