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
  ( SurfaceClass(..)
  , SurfaceContext
  , classify
  , readMetrics
  , currentSurface
  , onSurfaceChange
  , SurfaceView
  , reactive
  , bySurface
  , atLeast
  ) where

import Prelude

import Effect (Effect)
import Halogen.HTML as HH

-- | The coarse surface classes a design system reflows between. Ordered, so
-- | `atLeast` can express "Cozy or wider".
data SurfaceClass = Compact | Cozy | Roomy

derive instance eqSurfaceClass :: Eq SurfaceClass
derive instance ordSurfaceClass :: Ord SurfaceClass

instance showSurfaceClass :: Show SurfaceClass where
  show Compact = "Compact"
  show Cozy = "Cozy"
  show Roomy = "Roomy"

-- | The live surface: its class plus the raw metrics reactive components use for
-- | fluid layout, and the capabilities surface-specific components branch on
-- | (coarse pointer = touch; standalone = installed PWA).
type SurfaceContext =
  { class_ :: SurfaceClass
  , width :: Int
  , height :: Int
  , touch :: Boolean
  , standalone :: Boolean
  }

-- | Width → class. Breakpoints: Compact < 640 ≤ Cozy < 1024 ≤ Roomy.
classify :: Int -> SurfaceClass
classify w
  | w < 640 = Compact
  | w < 1024 = Cozy
  | otherwise = Roomy

-- | Raw viewport metrics from the host (window). FFI.
foreign import readMetrics
  :: Effect { width :: Int, height :: Int, touch :: Boolean, standalone :: Boolean }

-- | The current surface (metrics + derived class).
currentSurface :: Effect SurfaceContext
currentSurface = do
  m <- readMetrics
  pure
    { class_: classify m.width
    , width: m.width
    , height: m.height
    , touch: m.touch
    , standalone: m.standalone
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

-- | Is the surface at least this wide? `atLeast Cozy ctx` — for "Cozy or Roomy".
atLeast :: SurfaceClass -> SurfaceContext -> Boolean
atLeast c ctx = ctx.class_ >= c
