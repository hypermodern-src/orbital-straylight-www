-- | Hydrogen.Radix.Avatar — an image with a fallback (radix `Avatar`).
-- |
-- | A small STATEFUL primitive whose state is NOT a controlled value but a
-- | local lifecycle: the image's load status. radix tracks
-- | `"idle" | "loading" | "loaded" | "error"`; we mirror it as `Status`
-- | (`Idle | Loading | Loaded | Errored`). The `<img>` is rendered only while it
-- | has actually `Loaded`, and the `fallback` content is shown while it has not —
-- | so the consumer always sees *something* (initials, an icon) until/unless the
-- | image resolves.
-- |
-- | Unlike `Toggle`, there is no `Behavior.ControllableState` here: load status is
-- | driven by the browser via `HE.onLoad`/`HE.onError`, not by a parent prop. On
-- | `Receive`, a *changed* `src` resets the status back to `Loading` so a new image
-- | re-runs the load lifecycle.
-- |
-- | Parts (each a `ClassNames` in `Style`): `root` (a `span`), `image` (the `img`),
-- | `fallback` (a `span`). The stable behavioral attribute is
-- | `data-state="idle|loading|loaded|error"` on the `img`, matching radix.
-- |
-- | NOTE: radix's `AvatarFallback` supports a `delayMs` (delay before the fallback
-- | appears, to avoid a flash on fast loads). Skipped in v1 — the fallback shows
-- | immediately whenever `status /= Loaded`.
module Hydrogen.Radix.Avatar
  ( component
  , Input
  , Action
  , Output(..)
  , Query(..)
  , Slot
  , Status(..)
  , statusName
  , Style
  , defaultStyle
  , defaultInput
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import DOM.HTML.Indexed (HTMLspan)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Foundation.Style (ClassNames, cn, classes)

-- ─────────────────────────────────────────────────────────────────────────────
-- Public surface
-- ─────────────────────────────────────────────────────────────────────────────

-- | The image's load lifecycle (radix `ImageLoadingStatus`).
data Status = Idle | Loading | Loaded | Errored

derive instance eqStatus :: Eq Status

-- | The stable `data-state` realization CSS targets.
statusName :: Status -> String
statusName = case _ of
  Idle -> "idle"
  Loading -> "loading"
  Loaded -> "loaded"
  Errored -> "error"

-- | Per-part class lists: the `span` root, the `img`, and the fallback `span`.
type Style =
  { root :: ClassNames
  , image :: ClassNames
  , fallback :: ClassNames
  }

-- | Semantic default — a preset supplies an alternative `Style`.
defaultStyle :: Style
defaultStyle =
  { root: cn "rdx-avatar"
  , image: cn "rdx-avatar-image"
  , fallback: cn "rdx-avatar-fallback"
  }

type Input =
  { src :: String                      -- image source ("" = no image, fallback only)
  , alt :: String                      -- alt text for the image
  , fallback :: Array HH.PlainHTML      -- shown until/unless the image has loaded
  , rootAttrs :: Array (HH.IProp HTMLspan Action) -- escape hatch for preset Root attrs
                                                  -- (data-accent-color/data-radius/…)
  , style :: Style
  }

defaultInput :: Input
defaultInput =
  { src: ""
  , alt: ""
  , fallback: []
  , rootAttrs: []
  , style: defaultStyle
  }

-- | Emitted whenever the load status changes.
data Output = StatusChanged Status

-- | External inspection.
data Query a = GetStatus (Status -> a)

type Slot id = H.Slot Query Output id

-- ─────────────────────────────────────────────────────────────────────────────
-- Implementation
-- ─────────────────────────────────────────────────────────────────────────────

type State =
  { status :: Status
  , src :: String
  , alt :: String
  , fallback :: Array HH.PlainHTML
  , rootAttrs :: Array (HH.IProp HTMLspan Action)
  , style :: Style
  }

data Action
  = Receive Input
  | StatusChanged' Status

component :: forall m. H.Component Query Input Output m
component =
  H.mkComponent
    { initialState
    , render
    , eval: H.mkEval H.defaultEval
        { handleAction = handleAction
        , handleQuery = handleQuery
        , receive = Just <<< Receive
        }
    }

initialState :: Input -> State
initialState input =
  -- upstream useImageLoadingStatus: a missing/empty `src` resolves to 'error' (avatar.tsx:
  -- 156-158), NOT 'idle' — so onLoadingStatusChange('error') fires and the fallback shows.
  { status: if input.src == "" then Errored else Loading
  , src: input.src
  , alt: input.alt
  , fallback: input.fallback
  , rootAttrs: input.rootAttrs
  , style: input.style
  }

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  HH.span
    ([ classes st.style.root ] <> st.rootAttrs)
    ( (if st.src == "" then [] else [ renderImage st ])
        <> (if st.status == Loaded then [] else [ renderFallback st ])
    )

renderImage :: forall m. State -> H.ComponentHTML Action () m
renderImage st =
  -- upstream avatar.tsx mounts a bare `<Primitive.img>` (the radix-ui PRIMITIVE — and the
  -- @radix-ui/themes AvatarImage — emit NO data-state on the img; data-state is a Root-only
  -- concern). Parity: the img carries only src/alt/class (+ the load handlers).
  HH.img
    [ HP.src st.src
    , HP.alt st.alt
    , classes st.style.image
    , HE.onLoad \_ -> StatusChanged' Loaded
    , HE.onError \_ -> StatusChanged' Errored
    ]

renderFallback :: forall m. State -> H.ComponentHTML Action () m
renderFallback st =
  HH.span
    [ classes st.style.fallback ]
    (map HH.fromPlainHTML st.fallback)

handleAction :: forall m. Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  StatusChanged' next -> do
    st <- H.get
    when (st.status /= next) do
      H.modify_ _ { status = next }
      H.raise (StatusChanged next)
  Receive input -> do
    st <- H.get
    let
      -- A changed src restarts the load lifecycle; a cleared src resolves to 'error'
      -- (upstream treats missing/empty src as 'error', not 'idle'); otherwise keep status.
      next
        | input.src /= st.src = if input.src == "" then Errored else Loading
        | otherwise = st.status
    H.modify_ _
      { status = next
      , src = input.src
      , alt = input.alt
      , fallback = input.fallback
      , rootAttrs = input.rootAttrs
      , style = input.style
      }
    when (next /= st.status) (H.raise (StatusChanged next))

handleQuery :: forall m a. Query a -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  GetStatus reply -> do
    st <- H.get
    pure (Just (reply st.status))
