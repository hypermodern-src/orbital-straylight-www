# Hydrogen Integration TODO

## Status
- [x] Add hydrogen as git dependency in spago.yaml
- [x] Update registry to 73.2.0
- [x] Migrate Router to use `Hydrogen.Router` (IsRoute, RouteMetadata)

---

## Product × Pages Matrix

Each product is "armory-shaped" with 7 pages: Home, Features, Pricing, Docs, Dashboard, Settings, Legal

|                        | Home | Features | Pricing | Docs | Dashboard | Settings | Legal |
|------------------------|:----:|:--------:|:-------:|:----:|:---------:|:--------:|:-----:|
| **sensenet//cache**    |      |          |         |      |           |          |       |
| **sensenet//build**    |      |          |         |      |           |          |       |
| **sensenet//converge** |      |          |         |      |           |          |       |
| **sensenet//confirm**  |      |          |         |      |           |          |       |
| **sensenet//forge**    |      |          |         |      |           |          |       |
| **sensenet//publish**  |      |          |         |      |           |          |       |
| **omega//code**        |      |          |         |      |           |          |       |
| **omega//work**        |      |          |         |      |           |          |       |
| **omega//proxy**       |      |          |         |      |           |          |       |
| **omega//boost**       |      |          |         |      |           |          |       |

**Total: 10 products × 7 pages = 70 pages**

---

## Product × Hydrogen Matrix

|                        | Router | UI.Core | UI.Loading | UI.Error | Query | API.Client | SSG | HTML.Renderer | Data.Format |
|------------------------|:------:|:-------:|:----------:|:--------:|:-----:|:----------:|:---:|:-------------:|:-----------:|
| **sensenet//cache**    |   x    |         |            |          |       |            |     |               |             |
| **sensenet//build**    |   x    |         |            |          |       |            |     |               |             |
| **sensenet//converge** |   x    |         |            |          |       |            |     |               |             |
| **sensenet//confirm**  |   x    |         |            |          |       |            |     |               |             |
| **sensenet//forge**    |   x    |         |            |          |       |            |     |               |             |
| **sensenet//publish**  |   x    |         |            |          |       |            |     |               |             |
| **omega//code**        |   x    |         |            |          |       |            |     |               |             |
| **omega//work**        |   x    |         |            |          |       |            |     |               |             |
| **omega//proxy**       |   x    |         |            |          |       |            |     |               |             |
| **omega//boost**       |   x    |         |            |          |       |            |     |               |             |

**Legend:** `x` = done, ` ` = todo, `-` = not applicable

---

## Per-Product Tasks (× 10 products)

Each product needs:

### Routes (7 per product = 70 total)
- [ ] `/{product}` - Home
- [ ] `/{product}/features` - Features
- [ ] `/{product}/pricing` - Pricing
- [ ] `/{product}/docs` - Docs
- [ ] `/{product}/dashboard` - Dashboard (authenticated)
- [ ] `/{product}/settings` - Settings (authenticated)
- [ ] `/{product}/legal` - Legal

### Pages (7 per product = 70 total)
- [ ] Home page component
- [ ] Features page component
- [ ] Pricing page component
- [ ] Docs page component
- [ ] Dashboard page component
- [ ] Settings page component
- [ ] Legal page component

### Hydrogen Integration (per product)
- [ ] RouteMetadata (title, description, ogImage)
- [ ] Migrate to Hydrogen.UI.Core primitives
- [ ] Add loading states (Hydrogen.UI.Loading)
- [ ] Add error handling (Hydrogen.UI.Error)
- [ ] SSG static render (public pages)
- [ ] API.Client for dashboard/settings

---

## sensenet//cache
- [ ] Home
- [ ] Features
- [ ] Pricing
- [ ] Docs
- [ ] Dashboard
- [ ] Settings
- [ ] Legal

## sensenet//build
- [ ] Home
- [ ] Features
- [ ] Pricing
- [ ] Docs
- [ ] Dashboard
- [ ] Settings
- [ ] Legal

## sensenet//converge
- [ ] Home
- [ ] Features
- [ ] Pricing
- [ ] Docs
- [ ] Dashboard
- [ ] Settings
- [ ] Legal

## sensenet//confirm
- [ ] Home
- [ ] Features
- [ ] Pricing
- [ ] Docs
- [ ] Dashboard
- [ ] Settings
- [ ] Legal

## sensenet//forge
- [ ] Home
- [ ] Features
- [ ] Pricing
- [ ] Docs
- [ ] Dashboard
- [ ] Settings
- [ ] Legal

## sensenet//publish
- [ ] Home
- [ ] Features
- [ ] Pricing
- [ ] Docs
- [ ] Dashboard
- [ ] Settings
- [ ] Legal

## omega//code
- [ ] Home
- [ ] Features
- [ ] Pricing
- [ ] Docs
- [ ] Dashboard
- [ ] Settings
- [ ] Legal

## omega//work
- [ ] Home
- [ ] Features
- [ ] Pricing
- [ ] Docs
- [ ] Dashboard
- [ ] Settings
- [ ] Legal

## omega//proxy
- [ ] Home
- [ ] Features
- [ ] Pricing
- [ ] Docs
- [ ] Dashboard
- [ ] Settings
- [ ] Legal

## omega//boost
- [ ] Home
- [ ] Features
- [ ] Pricing
- [ ] Docs
- [ ] Dashboard
- [ ] Settings
- [ ] Legal

---

## Shared Infrastructure

### Router
- [x] `Hydrogen.Router` integrated
- [x] `IsRoute` instance
- [x] `RouteMetadata` instance
- [ ] Expand routes for all 70 pages
- [ ] Use `navigate` helper in Main.purs
- [ ] `isProtected` for Dashboard/Settings routes

### UI Layer
- [ ] Review `Straylight.UI` against `Hydrogen.UI.Core`
- [ ] Standardize loading spinners via `Hydrogen.UI.Loading`
- [ ] Standardize error display via `Hydrogen.UI.Error`

### Data Layer
- [ ] `Hydrogen.API.Client` for HTTP requests
- [ ] `Hydrogen.Query` for cached queries
- [ ] `Hydrogen.Data.RemoteData` for async state

### Static Generation
- [ ] `Hydrogen.SSG` for pre-rendering public pages
- [ ] `Hydrogen.HTML.Renderer` for server-side HTML

---

## Hydrogen Modules Reference

```
Hydrogen                    -- Main re-export module
Hydrogen.Router             -- Type-safe routing (IsRoute, RouteMetadata)
Hydrogen.Query              -- Data fetching with caching
Hydrogen.API.Client         -- HTTP API client (Affjax + Argonaut)
Hydrogen.SSG                -- Static site generation
Hydrogen.HTML.Renderer      -- HTML rendering
Hydrogen.Data.RemoteData    -- RemoteData type for async state
Hydrogen.Data.Format        -- Formatting utilities
Hydrogen.UI.Core            -- Core UI primitives
Hydrogen.UI.Loading         -- Loading state components
Hydrogen.UI.Error           -- Error boundary components
```

---

## Summary

| Category | Count |
|----------|-------|
| Products | 10 |
| Pages per product | 7 |
| Total pages | 70 |
| Hydrogen modules | 11 |
| Routes to define | 70 |
| Protected routes | 20 (Dashboard + Settings × 10) |
| Public routes | 50 |
