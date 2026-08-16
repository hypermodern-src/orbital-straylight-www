# Architecture

## Boundary

`cms` is an independent publishing service. It consumes the released
`straylight-web-middleware` package through a locked forge input and does not
import sibling source. It can be extracted from the monorepo without changing
its build.

PostgreSQL is the authority for editorial state. Database functions serialize
revision allocation and transitions so two studio sessions cannot silently
overwrite each other. The HTTP layer authenticates, parses, calls that narrow
store interface, maps expected failures, and adds delivery caching.

## Rendering

Canonical source is data, not executable application code:

- `markdown` is the normal article and paper source format.
- `typst` and `latex` support papers and generated artifacts.
- MDX is excluded because publishing arbitrary component execution from a CMS
  would turn editorial access into application-code execution.

The public sites will share consumer-side presentation components with the
future editorial preview. Rendered HTML/PDF and image derivatives are build
artifacts keyed by a revision hash, not second authorities for content.

## Auth seam

The first executable supports a constant-time checked bootstrap bearer token.
It records a configured actor ID on every mutation, never accepts actor identity
from a request header, and leaves editorial routes unavailable when the token
is absent. The `authorizeEditorial` seam is where internal OIDC verification
will land; the store and contract already carry stable actor IDs.

## Not in the first slice

- the Hydrogen editorial studio;
- object-storage upload signing and artifact builders;
- scheduled-publication worker and webhook/outbox delivery;
- import of the existing hard-coded MDX papers;
- DOI registration, Crossref, ORCID, and citation-resolution integrations.

Those are downstream of the publishing model instead of prerequisites hidden
inside it.
