---
name: credfeto-api-http-tests
description: Create a .http test file for every HTTP API endpoint that is exposed or consumed. Use whenever an HTTP API is being created, consumed, or modified.
---

# API HTTP Test Files

Every API endpoint (exposed or consumed) must have a corresponding `.http` test file:

- `<service>.http` for services you expose.
- `<api>.http` for APIs you consume.

Keep the `.http` file up to date whenever the endpoint's request shape, route, or response changes.
