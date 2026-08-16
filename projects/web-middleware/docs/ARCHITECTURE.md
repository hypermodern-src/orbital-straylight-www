# Architecture

## Durable boundary

The durable artifact is the HTTP behavior in `contract/openapi.yaml`:
operational paths, request IDs, response headers, error shapes, and lifecycle
semantics. WAI is an adapter. A Lean implementation is conforming when it
passes the same black-box contract tests; it does not need to reproduce the
Haskell module graph.

The current request path is:

```text
request ID
  -> request observation
  -> response hardening
  -> synchronous exception boundary
  -> JSON content-type normalization
  -> canonical path check
  -> bounded Unicode/JSON floor
  -> operational endpoints
  -> application
```

The order is intentional. Every response, including middleware rejections and
operational probes, receives a request ID, security headers, and an observation.
Async exceptions are never swallowed. Application exception details are logged
internally and never placed on the wire. Draining is terminal: a late dependency
callback cannot accidentally make a shutting-down process ready again.

## Deliberately outside this package

- Authentication and authorization are application/domain policy.
- CORS is an origin-specific allowlist, not a global convenience switch.
- CSP depends on the rendered application and asset graph.
- HSTS depends on TLS termination and domain ownership.
- Database error mapping belongs beside each database adapter.
- Prometheus or OpenTelemetry exporters consume observations; they do not own
  the request boundary.
- Product DTOs remain with their products.

Those seams avoid coupling the future Lean port to Clerk, Postgres, Servant,
Prometheus, or a particular Straylight application.

## Split posture

This directory owns its Cabal package, flake, lockfile, contract, docs, tests,
and executable. It imports no sibling source and can be extracted with:

```console
git filter-repo \
  --path projects/web-middleware/ \
  --path-rename projects/web-middleware/:
```
