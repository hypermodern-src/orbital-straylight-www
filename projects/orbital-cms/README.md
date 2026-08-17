# Orbital CMS

The publishing core for Orbital articles and research papers. It is a
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
DATABASE_URL=postgresql://localhost/orbital_cms nix run .#migrate
nix run
```

The migration runner records every applied version in `cms.schema_migrations`
and is safe to run again after the schema is current.

Editorial routes are disabled unless `ORBITAL_CMS_EDITOR_TOKEN` is set to at
least 32 bytes. The bootstrap token is intentionally a narrow seam: replace its
authorizer with the internal OIDC identity service before exposing the studio.

The Weyl `.plan` importer fetches the authoritative RSS metadata and article
HTML, converts the bodies to safe canonical Markdown, and is dry-run by default:

```console
nix run .#import-weyl-plan -- --output-dir /tmp/weyl-plan
ORBITAL_CMS_EDITOR_TOKEN=... nix run .#import-weyl-plan -- --publish
```

Published imports retain their original publication timestamp and a link to the
source article. Re-running the importer skips slugs that are already published.

Paper import registers content-addressed PDF metadata through the editorial API
after uploading objects to the public `orbital-publications` bucket. The CMS
attaches the registered PDF to the immutable paper revision in the same
transaction that creates that revision.

```console
nix run .#import-papers -- --source-dir /path/to/canonical-pdfs
SUPABASE_SERVICE_ROLE_KEY=... ORBITAL_CMS_EDITOR_TOKEN=... \
  nix run .#import-papers -- --source-dir /path/to/canonical-pdfs --publish
```

```console
nix flake check
```

See `contract/openapi.yaml` for the wire contract and `docs/EDITORIAL-MODEL.md`
for the workflow. Production deployment is documented in `docs/DEPLOY.md`.
