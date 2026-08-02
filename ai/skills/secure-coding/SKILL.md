---
name: credfeto-secure-coding
description: Handle secrets, validate untrusted input, sanitise output, model threats, and scan dependencies for vulnerabilities. Use whenever writing code that handles credentials, accepts external input (user input, API requests, file contents, env vars, message queues), produces output containing external data, exposes an endpoint, or introduces a new trust boundary.
---

# Secure Coding Practices

## Secrets and Credentials

- Never commit secrets, credentials, API keys, tokens, or passwords.
- If a secret is accidentally committed, treat it as compromised immediately: rotate it and purge it from history.
- Use environment variables, secrets managers, or platform vaults for all runtime secrets.
- Refer to the current repository's own AI instructions for its project-specific secrets management approach.

## Input Validation

- Validate all external input (user input, API requests, file contents, env vars, message queues) at the entry boundary before use.
- Reject input that does not conform to the expected shape, type, range, or format; never silently fix or guess malformed input.

## Output Sanitisation

- Sanitise all output containing external data for its context (HTML encoding, parameterised queries, shell escaping).
- Never construct queries, commands, or markup by string-concatenating untrusted input.

## Threat Modelling

- For any new feature handling data, exposing an endpoint, or introducing a trust boundary: model threats before writing code (who can call it, what can they send, what can go wrong). Document significant threats and mitigations.

## Dependency Vulnerability Scanning

- Scan dependencies for known vulnerabilities in CI; assess and resolve promptly.
- Refer to the current repository's own AI instructions for its project-specific scanning tool.
