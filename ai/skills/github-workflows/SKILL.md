---
name: credfeto-github-workflows
description: Author and review GitHub Actions workflow files and composite actions — third-party action policy, converting steps to actions/github-script, version pinning, step field ordering, permissions, checkout configuration, and composite-action extraction rules. Use whenever creating or modifying any .github/workflows/*.yml file or a .github/actions/*/action.yml composite action.
---

# GitHub Workflows Authoring

## Third-Party Action Policy

Classify every `uses:` reference before adding or reviewing:

- **Always allowed**: `actions/*` and `github/*`
- **Convert to github-script or local action**: all other third-party actions
- **Acceptable as-is**: actions requiring specialised external tooling not expressible via the GitHub API or bash (see Cannot Convert below)

When encountering existing third-party actions (including org-namespaced actions), replace with local equivalents where practical.

### Converting to github-script (wrap in local composite action)

Use `actions/github-script` to replace actions that:

- Read a file from the workspace
- Create, find, approve, or merge a pull request
- Delete a branch
- Add or sync labels on a PR or issue
- Assign a user to a PR or issue
- Enable auto-merge on a PR (via GraphQL)
- Check PR commits for merge commits
- Check repository visibility (public vs private)

Wrap the `actions/github-script` step in a **local composite action** at `.github/actions/<name>/action.yml` — never inline the script in workflow files.

The local action must:

- Mirror inputs and outputs of the replaced action so callers only change the `uses:` line
- Use `runs.using: composite`
- Pin `actions/github-script` to a specific version (e.g. `@v9.0.0`)
- Pass file paths or user-controlled strings via `env:` rather than string-interpolating into the `script:` body

#### Minimal composite action template

```yaml
name: "Action Name"
description: "What it does"

inputs:
  my-input:
    description: "..."
    required: true

outputs:
  my-output:
    description: "..."
    value: ${{steps.the-step.outputs.my-output}}

runs:
  using: composite
  steps:
    - name: "Do Thing"
      id: the-step
      uses: actions/github-script@v9.0.0
      env:
        MY_INPUT: ${{inputs.my-input}}
      with:
        script: |
          // use process.env.MY_INPUT, not ${{inputs.my-input}}, in the script body
          core.setOutput('my-output', result);
```

### Simple bash replacements

Replace these with a bash step — no `github-script` needed:

- **Merge conflict markers**: `git grep -rl '^<<<<<<< ' --` — fails if any file contains conflict markers
- **Case sensitivity conflicts**: `git ls-files | sort -f | awk 'BEGIN{prev=""} tolower($0)==tolower(prev){print prev; print $0} {prev=$0}'`
- **Tracked files matching `.gitignore`**: `git ls-files -i --exclude-standard`
- **Dotnet SDK version from global.json**: `jq -r '.sdk.version' src/global.json` — set `DOTNET_VERSION`; fall back to a default if absent

Keep step names consistent with the original so PR history is legible.

### Actions that cannot be converted

Do not replace these — specialised tooling required:

- **Docker toolchain**: `docker/build-push-action`, `docker/login-action`, `docker/setup-buildx-action`, `docker/setup-qemu-action`
- **AWS credential management**: `aws-actions/configure-aws-credentials`
- **Git operations** (rebase, auto-commit): `stefanzweifel/git-auto-commit-action`, `bbeesley/gha-auto-dependabot-rebase`
- **Security scanning**: `trufflesecurity/trufflehog`, `aquasecurity/trivy-action`
- **Multi-language linting**: `super-linter/super-linter`
- **Complex config-driven label sync**: `crazy-max/ghaction-github-labeler`

## Version Pinning (MANDATORY)

Pin all `uses:` to a specific released version tag. Never use `@latest`, `@main`, `@master`, bare major tags (e.g. `@v6`), or branch refs.

Correct: `uses: actions/github-script@v9.0.0`
Wrong: `@latest`, `@v6`, branch refs

When a merge or rebase produces conflicting pins for the same action (or for runtime versions such as `setup-node`/`setup-dotnet` versions), take the latest secure candidate.

Whenever you add or modify a `uses:` reference, check all actions in that file are on the latest released version:

1. For each `uses:`, run `gh api repos/<owner>/<action>/releases/latest --jq '.tag_name'`.
2. If behind, update in the same commit.
3. Never leave a file with a mix of updated and stale versions after touching it.

## Handling Node.js Deprecation Warnings

When reviewing a PR run and you see a message similar to:

> Node.js 20 actions are deprecated. The following actions are running on Node.js 20 and may not work as expected...

1. **Identify the action** named in the warning (e.g. `azure/sql-action@v2.3`).
2. **Locate the workflow file** that references it — search `.github/workflows/` (and any linked template repository) for it.
3. **Find the minimum compliant version**: enumerate candidate releases with `gh api --paginate repos/<owner>/<action>/releases --jq '.[].tag_name'`, then inspect tagged `action.yml`/`action.yaml` `runs.using` values to confirm the earliest release that ships a Node.js 24 runtime.
4. **Raise an issue in the repo that owns the workflow file**, with:
   - **Title**: `chore: update <action> to a Node.js 24 compatible version`
   - **Labels**: `AI-Work`, `dependencies`, `github-actions`, `High`
   - **Body**: current version, minimum compliant version (if one exists), a link to the upstream release, and the deprecation deadline.
5. Do **not** silently ignore the warning or defer it — raise the issue even if no compliant version is available yet (note that in the issue body).

## Bash Steps vs github-script

**Default to `actions/github-script`** for any step doing more than a single command.

Use `actions/github-script` for:

- Any step calling the GitHub REST or GraphQL API
- Any step processing git log output to make API decisions (e.g. creating branches, detecting missing releases)
- Any step reading or writing files as part of a workflow (not a build tool)
- Any step manipulating PR metadata (labels, assignees, draft state)
- Any step with conditional logic — `if/else` in JavaScript is clearer than nested bash conditionals
- Any step reading structured data (JSON, YAML) — use `JSON.parse` rather than `jq` pipelines

Bash is acceptable only for steps meeting **all** of:

- Single command or small sequence with no branching logic
- No GitHub API calls
- No structured data parsing
- Intent immediately obvious without comments (e.g. `sudo chown -R "$USER:$USER" "$GITHUB_WORKSPACE"`, `rm -fr "$HOME/.dotnet"`)

Extract non-trivial bash logic appearing in more than one workflow or composite action (after checkout) into a local composite action at `.github/actions/<name>/action.yml`.

### github-script API client (MANDATORY)

In `actions/github-script` steps, always use the `github` object for API calls:

- REST API: `github.rest.*`
- Pagination: `github.paginate`
- GraphQL: `github.graphql`

Never use `octokit` — it is not a valid variable in the `actions/github-script` context and will cause runtime failures.

## Step Field Ordering

Use this consistent field order — omit fields not needed. `name:` is always first.

### `run` steps

> **`shell:` is mandatory on every `run:` step. A `run:` step without `shell:` is invalid.**

```yaml
      - name: "Step Name"
        id: step-id           # only when output is referenced downstream
        if: <condition>       # only when conditionally run
        shell: bash
        run: |
          <commands>
        env:
          VARIABLE: "value"   # only when step-level env vars are needed
```

### `uses` steps

```yaml
      - name: "Step Name"
        id: step-id           # only when output is referenced downstream
        if: <condition>       # only when conditionally run
        uses: owner/action@vX.Y.Z
        env:
          MY_VAR: ${{inputs.some-input}}  # pass user-controlled values via env to prevent injection
        with:
          setting: "value"
```

**Rules:**

- `id:` follows `name:` — only when output is referenced downstream.
- `if:` follows `id:` (or `name:` when no `id:`).
- **`shell: bash` is mandatory on every `run:` step.**
- `env:` and `with:` values are **maps** — never list syntax.
- All string values must be double-quoted.
- Indentation: 2 spaces per YAML level; steps under `steps:` indented 6 spaces, fields within a step 8 spaces.

## Step Output Formatting

> Applies to GitHub Actions workflow steps only. Standalone shell scripts use ANSI-coloured `✓`/`✗` instead (see the shell-scripts skill).

| State | Character | Usage |
| --- | --- | --- |
| Pass / found / enabled | `✅` | Present, correct, or succeeded |
| Fail / missing / disabled | `❌` | Absent, wrong, or failed |
| Warning / skipped | `⚠️` | Skipped or needs attention |
| Info / in-progress | `ℹ️` | Neutral informational output |

Use `echo "::error::..."` (bash) or `core.setFailed(...)` (github-script) only for conditions that must fail the step.

github-script:

```javascript
core.info(`✅ Branch ${branchName} already exists`);
core.info(`✅ Updated global.json to version ${version}`);
core.info(`❌ Branch ${branchName} not found — creating`);
core.setFailed(`❌ Found ${mergeCommits.length} merge commit(s). Please rebase.`);
core.warning(`⚠️ No releases found — nothing to do`);
```

bash:

```bash
echo "✅ No merge conflict markers found."
echo "❌ Merge conflict markers found — resolve before merging."
echo "✅ src/global.json found — detected SDK version: $version"
echo "⚠️ src/global.json not found — using fallback version: 10.0.*"
```

### Surfacing key values without log diving

Emit important values (version numbers, PR URLs, branch names) with **both** `core.info` and `core.notice`. `core.notice` creates a job annotation visible in the run summary — no log scrolling needed:

```javascript
// \u001b[38;5;6m = ANSI 256-colour cyan; colours the value in the step log
// core.notice surfaces it as a job annotation visible in the run summary
core.info(`Version: \u001b[38;5;6m${version}`);
core.notice(`Version: ${version}`);
```

> **ANSI escape sequences — use the literal string, never the raw byte.**
> Write `\u001b` as six characters (`\`, `u`, `0`, `0`, `1`, `b`) inside JavaScript strings. Never insert the actual ESC byte (0x1B) into a YAML file — YAML forbids control characters and the workflow will be rejected.

Use `core.notice` for values a human would want to see first: build version, deployment target, branch created. Not for internal diagnostics.

## Dead Steps

Remove a step only if **both** are true:

1. Its output is never referenced by any subsequent step or job output.
2. It has no meaningful side effect — does not configure the environment, install tools, run a check that can fail the job, or produce an artifact.

Steps with side effects are never dead:

- `aws-actions/configure-aws-credentials` — configures shell environment with credentials
- `actions/setup-dotnet` / `actions/setup-node` — installs a runtime
- `trufflesecurity/trufflehog` — fails the job if secrets are found
- `aquasecurity/trivy-action` — fails the job if vulnerabilities are found
- `super-linter/super-linter` — fails the job on lint errors
- Any step writing to `$GITHUB_ENV` as its primary purpose

## Checkout Configuration

Use the minimum depth and tag fetching the job requires:

- **Default**: `fetch-depth: 1` — sufficient for read, build, or scan
- **Full history** (`fetch-depth: 0`): required only for `git diff --merge-base`, `git log`, `git rev-list`, or history traversal (changelog diffs, trufflehog, missing-release detection)
- **`fetch-tags: true`**: required only when the job reads, creates, or compares tags
- **`clean: true`**: include on self-hosted runners; may be omitted on GitHub-hosted

## Permissions

- Declare `permissions:` at workflow level (default: `contents: read`).
- Override at job level as needed.
- Never rely on default `GITHUB_TOKEN` write permissions without an explicit `permissions:` declaration.

## Workflow Structure

- Use `concurrency:` with `cancel-in-progress: true` on push-triggered feature-branch workflows.
- Use `cancel-in-progress: false` on release or dependency-merge workflows.
- Check required secrets with an explicit `run:` step before any dependent operation — fail fast with a clear error.

## Collapsing Multi-Step Groups

Before extracting into a composite action, consider collapsing into a **single `actions/github-script` step**. If the logic fits in 20–30 lines with no reuse value, collapsing is preferable.

Collapse when:

- Steps are conditional variants of the same operation
- No external tool requirements — only API calls or env-var writes
- Script body is readable without comments

Extract to a composite action when:

- Same sequence appears in two or more workflows or actions
- Non-trivial inputs/outputs callers need to vary
- Steps mix `actions/github-script` with other `uses:` steps

## Composite Action Placement

All local composite actions live under `.github/actions/<name>/action.yml`. Extract any step pattern that appears in more than one workflow or action — do not copy-paste.

> **Any `uses:` step — local or remote — must only appear after `actions/checkout` has run.** Keep pre-checkout steps as inline `run:` bash steps (secret checks, workspace ownership fixes, env setup).

### Infrastructure steps that repeat across every job

Boilerplate setup blocks are high-value extraction targets. Examples:

- Secret presence check → thin local action or inline `github-script` step failing with ❌ if empty
- Workspace ownership fix (`sudo chown`) and active env var setup → keep as inline `run:` bash steps

When extracting pure-infrastructure steps, the action may have no `outputs:` and only optional inputs for minor variants.

### Unifying invocations that differ only in value source

When the same action is called in multiple places with identical parameters except one value sourced differently, extract into a local action requiring that value as an explicit input:

```yaml
# pull_request trigger — PR is the current event
pr-number: ${{github.event.pull_request.number}}

# push trigger — PR was just created by a previous step
pr-number: ${{steps.open-pr.outputs.pr_number}}
```

## Composite Action Inputs vs Environment Variables

Composite actions must never silently depend on caller-set env vars — invisible contracts cause obscure failures.

### Prefer explicit inputs

Declare every required value as a named input with `required: true`:

```yaml
# action.yml
inputs:
  github-token:
    description: "GitHub token with write access"
    required: true
  pr-number:
    description: "Pull request number"
    required: true
```

```yaml
# caller
uses: ./.github/actions/my-action
with:
  github-token: ${{secrets.SOURCE_PUSH_TOKEN}}
  pr-number: ${{github.event.pull_request.number}}
```

### When env vars cannot be avoided

Add a validation step as the **first step**, checking each required env var and failing immediately with a clear ❌ naming the missing variable:

```yaml
    - name: "Validate Environment"
      uses: actions/github-script@v9.0.0
      with:
        script: |
          const required = ['DOTNET_VERSION', 'NUGET_FEED'];
          const missing = required.filter(k => !process.env[k]);
          if (missing.length) {
            core.setFailed(`❌ Required environment variables are not set: ${missing.join(', ')}`);
          } else {
            core.info('✅ All required environment variables are set');
          }
```

**Rules:**

- Prefer `inputs:` over env var dependencies — explicit over implicit.
- Never read an env var without declaring it as an input or validating its presence first.
- Validation must be the first step.
- Error messages must name every missing variable.
