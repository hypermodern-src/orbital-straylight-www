# Hero Copy Experiment

Epsilon-greedy bandit testing hero messaging variants.

## Hypothesis

Different value propositions resonate with different audiences. Testing:

- Direct/functional messaging
- Pain-point focused
- Social proof focused
- Technical credibility

## Variants

### control (current)

```
headline: "Your AI broke it."
subhead: "We fix it."
tagline: "Vibe-coded apps cleaned up by engineers who understand what the AI was trying to do. Same-day turnaround. Flat rate."
cta: "GET QUOTE"
```

### direct

```
headline: "AI-Generated Code Cleanup"
subhead: "Professional debugging service"
tagline: "Submit your repo. Get a flat-rate quote in under an hour. Ship the fix same-day."
cta: "GET STARTED"
```

### pain

```
headline: "Cursor wrote 200 files."
subhead: "47 have circular imports."
tagline: "You're not bad at prompting. The tools are bad at code. We fix what AI breaks."
cta: "FIX MY CODE"
```

### social

```
headline: "847 repos fixed."
subhead: "100% satisfaction."
tagline: "Trusted by engineers at Vercel, Stripe, Linear. Average fix time: 4 hours."
cta: "JOIN THEM"
```

## Metrics

**Primary:** `form_submit` (conversion)
**Secondary:**

- `cta_click` (engagement)
- `scroll_depth` (interest)
- Time on page

## Statsig Setup

1. Create experiment `hero_copy` in Statsig console
2. Enable "Autotune" for epsilon-greedy allocation
3. Set primary metric to `form_submit`
4. Add variants with parameters above
5. Replace `client-PLACEHOLDER` with real SDK key

## Bandit Parameters

- **Epsilon:** 0.1 (10% exploration)
- **Autotune:** Enabled (Statsig handles allocation)
- **Min sample:** 100 users per variant before reallocation

## Implementation

Client-side:

```javascript
const { headline, subhead, tagline, cta } = window.statsig.getHeroVariant();
```

Server-side (future): Use Statsig Node SDK for SSR with consistent bucketing.
