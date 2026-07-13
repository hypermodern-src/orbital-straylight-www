# Orbital Sales Pages — Handoff for Claude Code

**Purpose:** implementation brief for the CACHE and BUILD launch pages. Written 2026-07-12 from PM (Jesse Wilson) decisions. Read this first; consult `01-Orbital-Project-Handoff-v2.md` for project-wide rules and `Orbital-Business-Plan-v11.md` §4/§7/§8 for product and pricing background.

## What to build

Marketing site for the first two product launches: **CACHE** (verified binary storage, public release August 2026) and **BUILD** (typed build system, public release September 2026). The **Orbital Confirm** runner follows Oct–Nov; leave room for it.

## Decided architecture (do not relitigate)

1. **Separate page per product, one shared pricing page, one subscription.** Each product page sells one job to one visitor. Billing is platform-level: one Orbital account, usage-based metering across products. No per-product SKUs, no "subscribe to both" bundle. Adopting a second product is a config line, not a purchase.
2. **Tiers gate account-level things** (throughput, retention, on-prem, SLAs), never which products you may use. Seats free. Per-product usage stays itemized on the bill.
3. **No SSO tax.** Security basics (SSO, audit logs) are free at every tier. We charge for scale and enterprise controls.
4. **Two visitor paths matching the two beachheads:** developers → speed/price/docs/self-serve; compliance and safety-critical buyers → separate verification path, founder-contact CTA (that sale is founder-led).

## Page structure (per product page)

- Hero: one sentence, one-line config diff in a copy-paste block, one measured claim with basis linked. CTA "Start free — no credit card"; secondary CTA to the verification path.
- Benchmarks with published, reproducible methodology.
- Quickstart under 5 minutes; docs one click from everywhere.
- Trust signals: GitHub repo links, public changelog, status page, licenses.

## Conversion mechanics to implement

- Free tier gated on consumption, not features (competitive norm: Cachix 5GB, Blacksmith 3,000 min, BuildBuddy 3-seat teams). Exact allowances TBD by team.
- Usage receipts at limit moments: "this month Orbital saved you X hours / $Y vs. GitHub Actions" (figures must be measured, never estimated).
- In-product cross-sell (e.g. BUILD suggests CACHE from real build-graph data), not checkout upsell.
- Planned differentiator: self-serve proof bot that PRs a one-line config change against the visitor's repo and reports before/after times on their own code.

## Blocked / pending — do not fill these in

- **All pricing numbers.** The "$0.003/min undercuts everyone" claim is stale (Q&A 1.7 unresolved). Build the pricing page with placeholders.
- **On-prem/air-gapped claims** (pending team confirmation, see Q&A).
- **BUILD vs. runner launch sequencing** (Q&A 2.1) may reorder page priorities.
- Final naming sweep pending (never use: Straylight, sensenet, weyl; aliases Straylight/Leaderboard Confirm are being retired).

## Style rules (inherited from the project, mandatory)

- No em-dashes anywhere.
- Lay-readable copy; no unexplained jargon.
- Bold Orbital product names on first use.
- Every quantitative claim labeled measured/target/estimate with its basis. No unmeasured numbers on the site.
- Never mention WARRANT or crypto positioning.

## Suggested Claude Code setup

1. Create a fresh repo (e.g. `orbital-site`), separate from this business-plan folder.
2. Copy this file into the repo root; have `/init` generate CLAUDE.md, then add: "Read 02-Sales-Page-Handoff.md before any copy or design work; its decisions and style rules are binding."
3. First milestone: static pages with placeholder pricing (CACHE page, BUILD page, shared pricing page, verification path page), copy drafted to the rules above.
