# Straylight CMS

The publishing core for Straylight articles and research papers. It is a
split-ready project with its own database schema, service, contract, dependency
lock, and checks.

The first slice deliberately separates three concerns:

- PostgreSQL owns immutable revisions, workflow transitions, publication
  readiness, authors, paper metadata, assets, and audit events.
- The Haskell service exposes a small editorial API and cache-aware public
  delivery API behind `straylight-web-middleware`.
- Sites own rendering. The CMS returns canonical Markdown, Typst, or LaTeX
  source; it never executes untrusted MDX or stores shadow HTML.

## Run it

Create a PostgreSQL database, copy `.env.example` into your secret-management
workflow, then:

```console
DATABASE_URL=postgresql://localhost/straylight_cms nix run .#migrate
nix run
```

The migration runner records version `1` in `cms.schema_migrations` and is safe
to run again after the schema is current.

Editorial routes are disabled unless `STRAYLIGHT_CMS_EDITOR_TOKEN` is set to at
least 32 bytes. The bootstrap token is intentionally a narrow seam: replace its
authorizer with the internal OIDC identity service before exposing the studio.

```console
nix flake check
```

See `contract/openapi.yaml` for the wire contract and `docs/EDITORIAL-MODEL.md`
for the workflow.
