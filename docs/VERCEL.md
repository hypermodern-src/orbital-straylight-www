# Vercel project map

This file records source ownership separately from Vercel project settings.
Changing this repository does not authorize a production relink.

| Vercel project | Canonical source here | Current deployment state | Next change |
| --- | --- | --- | --- |
| `orbital-showroom` | `projects/hydrogen/examples` | Manual static deployment; exact Hydrogen.Radix gallery | Attach after a preview build from the project root |
| `hypermodern-website` | `projects/hypermodern-consulting` | Manual static deployment | Attach after reproducing the current static output |
| `straylight-web` | `projects/straylight-web` | Linked to the legacy GitHub organization | Move only after an equivalent preview succeeds |
| `reinit-dx` | `projects/reinit-dx` | Production still comes from `reinit-dx-website` | Cut over from the Next.js wrapper to the canonical SSG target |
| `orbital-web-jw` | `projects/orbital-web-jw` | New prebuilt deployment; legacy GitHub auto-deploy remains in an unavailable Vercel team | Attach a custom domain only after resolving the launch blockers and intended production origin |

`straylight-website` is a confirmed Hydrogen-era static deployment, but its
exact standalone source tree has not been recovered. It is intentionally not
represented as a project yet.

Other projects in the Vercel account (Weyl, IDORU/v0 experiments, and unrelated
one-off sites) are outside this repository unless their source and ownership are
explicitly brought into scope.
