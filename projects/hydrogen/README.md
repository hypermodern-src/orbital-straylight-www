# HYDROGEN

A PureScript/Halogen web framework for building robust web applications.

```
    ██╗  ██╗██╗   ██╗██████╗ ██████╗  ██████╗  ██████╗ ███████╗███╗   ██╗
    ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██╔═══██╗██╔════╝ ██╔════╝████╗  ██║
    ███████║ ╚████╔╝ ██║  ██║██████╔╝██║   ██║██║  ███╗█████╗  ██╔██╗ ██║
    ██╔══██║  ╚██╔╝  ██║  ██║██╔══██╗██║   ██║██║   ██║██╔══╝  ██║╚██╗██║
    ██║  ██║   ██║   ██████╔╝██║  ██║╚██████╔╝╚██████╔╝███████╗██║ ╚████║
    ╚═╝  ╚═╝   ╚═╝   ╚═════╝ ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═══╝
```

> *The most fundamental element. The foundation everything else builds on.*

Hydrogen is two things that share a repo:

1. **A component library** — a hand-written port of **[`radix-ui/primitives`](src/Hydrogen/Radix/PORTING.md)**
   to native PureScript/Halogen. All 32 user-facing primitives are ported (Dialog,
   Select, Slider, Menubar, Toast, …), with **no radix npm dependency and no
   external-JS FFI** — even the floating-ui positioning engine is ported native.
   This is where the active work is. radix-ui is vendored read-only as the reference
   spec; the port is diffed against the *real upstream React render* via a three-oracle
   verification gate (DOM / ARIA / WAI-ARIA-APG keyboard).
2. **An application framework** — Query, Router, API Client, SSG, RemoteData, UI
   primitives (the "Features" below). The original seed; stable.

**Status:** breadth is complete (every primitive ported + compiling); behavioral
parity is mid-verification and explicitly tracked — see
[`src/Hydrogen/Radix/DEPTH-AUDIT.md`](src/Hydrogen/Radix/DEPTH-AUDIT.md),
[`ARIA-AUDIT.md`](src/Hydrogen/Radix/ARIA-AUDIT.md), and Linear epic **STR-330**.
Build & contributor guide: [`CLAUDE.md`](CLAUDE.md).

## Framework features

- **[Query](docs/query.md)** - Data fetching with caching, deduplication, stale-while-revalidate
- **[Router](docs/router.md)** - Type-safe routing with custom ADTs and metadata
- **[API Client](docs/api-client.md)** - HTTP client with JSON, auth, logging
- **[SSG](docs/ssg.md)** - Static site generation with route integration
- **[UI Primitives](docs/ui.md)** - Loading, error, empty states
- **[Formatting](docs/format.md)** - Bytes, durations, numbers

## Installation

```yaml
# spago.yaml
workspace:
  packageSet:
    registry: 73.2.0
  extraPackages:
    hydrogen:
      path: ../hydrogen

package:
  dependencies:
    - hydrogen
```

## Development

Spago is the only supported PureScript build graph. The pinned local CLI requires
Node 22.5 or newer.

```sh
npm ci
npm run check
npm run bundle:gallery
npm run bundle:themes-port
npm run bundle:themes-interactive
```

`npm run check` also compiles the Supabase and Clerk integration packages, so
their separate Spago graphs cannot drift from the core library.

`nix develop` supplies Node and `purs`; it does not introduce a second build
system. `nix run .#check` executes the same npm/Spago check.

## Quick Start

```purescript
import Hydrogen.Query as Q
import Hydrogen.Data.RemoteData as RD
import Hydrogen.Router (class IsRoute, navigate)
import Hydrogen.UI.Core (cls, row, column)
import Hydrogen.UI.Loading (loadingState)
import Hydrogen.UI.Error (errorState)

-- Data fetching with caching
client <- Q.newClient
state <- Q.query client
  { key: ["user", userId]
  , fetch: Api.getUser userId
  }

-- state contains RemoteData + metadata
-- state :: { data :: RemoteData String User, isStale :: Boolean, isFetching :: Boolean }

-- Combine multiple queries with ado (RemoteData is a lawful Monad!)
let dashboard = ado
      user <- userState.data
      posts <- postsState.data
      stats <- statsState.data
      in { user, posts, stats }

-- Render based on RemoteData
render = RD.fold
  { notAsked: mempty
  , loading: loadingState "Loading..."
  , failure: \e -> errorState e
  , success: renderDashboard
  }
  dashboard
```

## Modules

| Module | Description |
|--------|-------------|
| `Hydrogen.Query` | Data fetching, caching, pagination, batching |
| `Hydrogen.Data.RemoteData` | Lawful Monad for async state (NotAsked/Loading/Failure/Success) |
| `Hydrogen.Router` | Type-safe routing, navigation, link interception |
| `Hydrogen.API.Client` | HTTP client with auth and JSON |
| `Hydrogen.SSG` | Static site generation, meta tags |
| `Hydrogen.UI.Core` | Layout primitives, class utilities |
| `Hydrogen.UI.Loading` | Spinners, skeletons, loading states |
| `Hydrogen.UI.Error` | Error cards, empty states |
| `Hydrogen.Data.Format` | Byte/duration/number formatting |
| `Hydrogen.HTML.Renderer` | Render Halogen HTML to strings |

## Component library (`Hydrogen.Radix`)

The radix-ui port. 32 primitives across a layered substrate — see
**[`src/Hydrogen/Radix/PORTING.md`](src/Hydrogen/Radix/PORTING.md)** for the porting
contract and **[`CLAUDE.md`](CLAUDE.md)** for build/test/verification.

| Layer | Modules |
|-------|---------|
| `Hydrogen.Radix.Behavior.*` | ControllableState, Presence, DismissableLayer, FocusScope, RovingFocus, Direction, ScrollLock, Id |
| `Hydrogen.Radix.Float.*` | Compute, Popper — native closed-form floating-ui port |
| `Hydrogen.Radix.Foundation.*` | Color, Style, Portal, Dom, Envelope |
| `Hydrogen.Radix.*` | 32 primitives: Dialog, AlertDialog, Popover, Tooltip, HoverCard, DropdownMenu, ContextMenu, Menubar, Select, Tabs, Accordion, Collapsible, RadioGroup, Checkbox, Switch, Toggle, ToggleGroup, Toolbar, Slider, ScrollArea, NavigationMenu, Toast, Progress, Avatar, Form, OneTimePasswordField, PasswordToggleField, Label, Separator, AspectRatio, AccessibleIcon, VisuallyHidden |
| `Hydrogen.Themes.*` | the radix-themes preset (`rt-*` classes) over the primitives |

Verified against the real upstream React render through three CI-gated oracles
(DOM-identical / ARIA-tree / WAI-ARIA-APG keyboard) in
[`testing/playwright/`](testing/playwright/). The remaining verification backlog is
in [`DEPTH-AUDIT.md`](src/Hydrogen/Radix/DEPTH-AUDIT.md) and Linear **STR-330**.

## Documentation

- **[Query Guide](docs/query.md)** - Caching, deduplication, stale-while-revalidate, pagination
- **[Router Guide](docs/router.md)** - Route ADTs, metadata, navigation
- **[API Client Guide](docs/api-client.md)** - HTTP requests, auth, error handling
- **[SSG Guide](docs/ssg.md)** - Static generation, "write once render anywhere"
- **[UI Guide](docs/ui.md)** - Loading states, error handling, layout

## Design Principles

### Lawful Algebra

`RemoteData` is a **lawful Monad** — use `do` or `ado` syntax freely:

```purescript
-- Applicative (parallel semantics)
ado
  user <- userState.data
  posts <- postsState.data
  in { user, posts }

-- Monad (sequential semantics)  
do
  user <- userState.data
  posts <- postsState.data
  pure { user, posts }
```

Query state is split into `RemoteData` (the data) + metadata (`isStale`, `isFetching`).
This enables stale-while-revalidate UX while keeping the algebra lawful.

### Type-Safe by Default

Routes are ADTs with typeclass instances, not stringly-typed:

```purescript
data Route = Home | User String | Settings
navigate (User "123")  -- Type-safe, not navigate "/user/123"
```

### Framework, Not Library

Hydrogen provides *patterns* not just utilities:
- Query caching patterns that work
- Route metadata for SSG and auth
- Consistent state handling across components

## License

MIT
