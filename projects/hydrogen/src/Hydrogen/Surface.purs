-- | Hydrogen's third frame axis: the **Surface** — the rendering target a UI
-- | reflows into. (Auth = `Hydrogen.Frame.AuthProvider`; Deploy = the build-level
-- | deploy target; Surface = here.)
-- |
-- | A real design system has two kinds of component, and must move between them
-- | smoothly:
-- |
-- |   * REACTIVE — one rendering that reflows (responsive); written once, adapts
-- |     to width. Build with `reactive`.
-- |   * SURFACE-SPECIFIC — distinct renderings per surface class (a sidebar on
-- |     Roomy, a bottom bar on Compact); the right one is chosen for the live
-- |     surface and swapped as it reflows across a breakpoint. Build with
-- |     `bySurface`.
-- |
-- | Both produce a `SurfaceView`, so an app threads ONE live `SurfaceContext`
-- | (subscribe via `onSurfaceChange`) and every component — reactive or
-- | surface-specific — reflows uniformly. `Surface` is the notion ORBITAL's
-- | components will be written against; for now it's the vocabulary.
module Hydrogen.Surface
  ( Host(..)
  , SurfaceClass(..)
  , SurfaceContext
  , classify
  , readMetrics
  , currentSurface
  , onSurfaceChange
  , SurfaceView
  , reactive
  , bySurface
  , byHost
  , atLeast
  ) where

import Prelude

import Effect (Effect)
import Halogen.HTML as HH

-- | The HOST a hydrogen app renders into — the target/shell axis (orthogonal to
-- | size). A component can target a host, not only a width: `Browser` (a normal
-- | web tab), `InstalledPWA` (added to home screen / standalone display-mode), or
-- | `Native` (a future native shell, which sets `window.__hydrogen_native__`).
-- | The same bundle distinguishes Browser vs InstalledPWA at runtime; Native is a
-- | separate build target whose shell flags itself.
data Host = Browser | InstalledPWA | Native

derive instance eqHost :: Eq Host

instance showHost :: Show Host where
  show Browser = "Browser"
  show InstalledPWA = "InstalledPWA"
  show Native = "Native"

-- | The coarse surface classes a design system reflows between. Ordered, so
-- | `atLeast` can express "Cozy or wider".
data SurfaceClass = Compact | Cozy | Roomy

derive instance eqSurfaceClass :: Eq SurfaceClass
derive instance ordSurfaceClass :: Ord SurfaceClass

instance showSurfaceClass :: Show SurfaceClass where
  show Compact = "Compact"
  show Cozy = "Cozy"
  show Roomy = "Roomy"

-- | The live surface: its host (target shell) and size class, plus the raw
-- | metrics reactive components use for fluid layout and the touch capability
-- | surface-specific components branch on.
type SurfaceContext =
  { host :: Host
  , class_ :: SurfaceClass
  , width :: Int
  , height :: Int
  , touch :: Boolean
  }

-- | Width → class. Breakpoints: Compact < 640 ≤ Cozy < 1024 ≤ Roomy.
classify :: Int -> SurfaceClass
classify w
  | w < 640 = Compact
  | w < 1024 = Cozy
  | otherwise = Roomy

-- | Raw viewport metrics + host flags from the window. FFI.
foreign import readMetrics
  :: Effect
       { width :: Int
       , height :: Int
       , touch :: Boolean
       , standalone :: Boolean
       , native :: Boolean
       }

-- | The current surface (metrics + derived host & class).
currentSurface :: Effect SurfaceContext
currentSurface = do
  m <- readMetrics
  pure
    { host: if m.native then Native else if m.standalone then InstalledPWA else Browser
    , class_: classify m.width
    , width: m.width
    , height: m.height
    , touch: m.touch
    }

foreign import onResize :: Effect Unit -> Effect (Effect Unit)

-- | Subscribe to surface changes (resize/rotate). The callback fires with the
-- | fresh `SurfaceContext` — wire it to app state so the UI reflows. Returns the
-- | unsubscribe effect.
onSurfaceChange :: (SurfaceContext -> Effect Unit) -> Effect (Effect Unit)
onSurfaceChange k = onResize (currentSurface >>= k)

-- | A surface-aware view: a function of the live surface. Both `reactive` and
-- | `bySurface` produce one, so the app reflows them uniformly.
type SurfaceView w i = SurfaceContext -> HH.HTML w i

-- | A reactive component: one rendering that reflows. It may read `ctx.width`
-- | for fluid layout but renders the same structure across classes.
reactive :: forall w i. (SurfaceContext -> HH.HTML w i) -> SurfaceView w i
reactive = identity

-- | A surface-specific component: a distinct rendering per `SurfaceClass`, swapped
-- | as the surface reflows across a breakpoint.
bySurface :: forall w i. (SurfaceClass -> HH.HTML w i) -> SurfaceView w i
bySurface f ctx = f ctx.class_

-- | A host-specific component: a distinct rendering per `Host` (e.g. a web nav
-- | vs an installed-PWA bottom bar vs a native chrome).
byHost :: forall w i. (Host -> HH.HTML w i) -> SurfaceView w i
byHost f ctx = f ctx.host

-- | Is the surface at least this wide? `atLeast Cozy ctx` — for "Cozy or Roomy".
atLeast :: SurfaceClass -> SurfaceContext -> Boolean
atLeast c ctx = ctx.class_ >= c
