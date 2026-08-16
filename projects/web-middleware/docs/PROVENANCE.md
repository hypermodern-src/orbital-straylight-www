# Provenance

Source inspected: `hypermodern-consulting/looking-local` at commit
`1b21b28c36f8756f70ab20664b6ce59f342b04f7` (`test: cover content intake in
release smoke`).

The source repository's `NOTICE.md` and `OWNERSHIP.toml` classify
`HyperModern.*` Haskell modules and the generic server scaffolding as
Hypermodern LLC house code licensed to the client. Straylight's licensed reuse
is limited here to that generic side of the ownership boundary.

| Source | Adaptation |
| --- | --- |
| `HyperModern.Server.Error` | Preserved the stable `code` / `message` / optional `details` JSON object; removed the Servant dependency. |
| `HyperModern.Server.Sanitize` | Preserved recursive Unicode validation and request-body replay; added a hard body limit for generic use. |
| `HyperModern.Server.Config` | Preserved parse-once, fail-before-bind, accumulated configuration faults; reduced it to runner policy. |
| `HyperModern.Server.Log` and the generic portion of `LookingLocal.Server.Application` | Replaced Katip and query-bearing text logs with injectable, structured, query-free observations. |
| `HyperModern.Server.Spine` and `LookingLocal.Server.Handler.Health` | Retained the warm/ready/draining lifecycle model without the Looking Local Postgres notification bus. |
| `server/app/Main.hs` | Retained ready-after-bind and drain-before-close shutdown ordering in a domain-free runner. |

No `LookingLocal.*` handler, store, wire type, contract, schema, authentication
configuration, telemetry vocabulary, or product composition was copied.
