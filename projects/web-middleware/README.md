# Straylight web middleware

The shared HTTP policy boundary for Straylight web services. Today it is a
small Haskell/WAI library and reference Warp runner. Its public contract is
HTTP, not Haskell: applications can adopt the behavior now and keep it when the
implementation moves to Lean.

The initial stack provides:

- canonical, validated `X-Request-Id` propagation;
- privacy-bounded structured request observations;
- uniform JSON middleware errors;
- bounded hostile-text rejection for path, query, and JSON input;
- conservative security headers without guessing CSP, HSTS, or CORS policy;
- `/healthz` liveness and warm/ready/draining `/readyz` lifecycle probes;
- opaque synchronous exception handling and graceful runner shutdown.

## Build

```console
nix flake check
nix run
```

The reference runner listens on `0.0.0.0:8080` by default. Its environment
contract is:

| Variable | Default | Constraint |
| --- | ---: | --- |
| `STRAYLIGHT_MIDDLEWARE_HOST` | `0.0.0.0` | non-empty |
| `STRAYLIGHT_MIDDLEWARE_PORT` | `8080` | `1..65535` |
| `STRAYLIGHT_MIDDLEWARE_SHUTDOWN_SECONDS` | `10` | `1..300` |
| `STRAYLIGHT_MIDDLEWARE_MAX_JSON_BODY_BYTES` | `1048576` | `1..67108864` |

All configuration faults are reported together before the socket binds.

## Use

Allocate one runtime during boot, apply `middleware runtime` to a WAI
application, and call `markReady` only after the listener and required
dependencies are warm. On shutdown, call `beginDrain` before closing the
listening socket.

See [`contract/openapi.yaml`](contract/openapi.yaml) for the wire contract and
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the replacement boundary.
