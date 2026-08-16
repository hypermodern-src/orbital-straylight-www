# Deployment

Orbital CMS runs as a stateless Fly Machine in `iad` and uses a Supabase
PostgreSQL project in `us-east-1`. The database region chooses the compute
region: editorial and delivery queries should not cross an ocean.

The production service is `orbital-cms.fly.dev`. Its Supabase project is
`orbital-cms` (`zorahcnswubdvqehhxve`) in organization
`uxdcpziilyyyhjejxsqe`.

The image is built by Fly's x86_64 remote builder from the monorepo root. The
Docker build overrides the locked private middleware input with the exact
`projects/web-middleware` source in its build context, so the remote builder
needs no forge credential and the normal independent Nix build remains pinned.

## Secrets

The Fly app requires exactly two secrets:

- `DATABASE_URL`: the TLS-required Supabase PostgreSQL connection string;
- `ORBITAL_CMS_EDITOR_TOKEN`: at least 32 cryptographically random bytes.

`ORBITAL_CMS_EDITOR_ID` is non-secret and defaults to `bootstrap`. Never put any
of these secret values in Git, build arguments, command history, or logs.

## Deploy

Run from the monorepo root:

```console
flyctl deploy --remote-only --ha=false --config projects/orbital-cms/fly.toml
```

Every deploy first runs `/bin/orbital-cms-migrate` in Fly's temporary release
Machine. A failed migration aborts the release; an already-current migration is
a no-op. Fly then rolls the application Machine and waits for `/readyz`.

Verify both process and delivery surfaces:

```console
curl -fsS https://orbital-cms.fly.dev/healthz
curl -fsS https://orbital-cms.fly.dev/readyz
curl -fsS https://orbital-cms.fly.dev/v1/publications
```
