-- | Multi-component behavioral-invariance subject (STR-383, batch E). Renders the two
-- | HEAVY stateful primitives — ScrollArea and Toast — each in a `[data-invariance="<Component>"]`
-- | group containing four `[data-preset]` variants (unstyled · themes · shadcn · daisy) that
-- | differ ONLY in their Style class lists. The invariance gate (invariance.mjs) proves, per
-- | group, that the behavioral DOM (role / aria-* / data-* / tabindex / inline-style geometry /
-- | tag tree) is byte-identical across all four presets — same inputs everywhere, only the class
-- | vocabulary varies.
-- |
-- | Both subjects render AT REST with a deterministic structural surface (no timers, no user
-- | interaction needed for the at-rest DOM):
-- |
-- |   * ScrollArea — `type="always"`-equivalent: the scrollbar(s) are mounted unconditionally,
-- |     so at rest the Root carries the viewport (data-radix-scroll-area-viewport, overflow
-- |     shorthand), the scrollbar (data-orientation / data-state=visible / the var-shaped inline
-- |     style), and the thumb (data-state=visible / translate3d). The thumb geometry is real
-- |     measured px, which the px-normalizer tokenizes — but here it is class-INDEPENDENT, so the
-- |     structural surface is byte-identical across presets. Same content/size/scrollbars across
-- |     all four skins; only the per-part class lists vary.
-- |
-- |   * Toast — controlled `open=Just true` held open with `duration=Nothing` (the at-rest
-- |     oracle's clock-defused path): the region wrapper (role=region / aria-label / tabindex=-1),
-- |     the focus proxies, the <ol>, and the <li> (data-state=open / data-swipe-direction /
-- |     user-select+touch-action style / tabindex=0) with title / description / action / close —
-- |     all class-independent. The SR-announce mirror is PORTALED to document.body, escaping the
-- |     `[data-preset]` wrapper entirely, so the gate (which extracts each preset SUBTREE) never
-- |     sees it — it cannot perturb invariance. Same inputs across all four skins; only the
-- |     per-part class lists vary.
-- |
-- | NOT a pixel story — excluded from the gallery manifest.
module Gallery.Story.InvE (story) where

import Prelude

import Data.Array (mapWithIndex)
import Data.Maybe (Maybe(..))
import Effect.Aff (Aff)
import Gallery.Story (Story, StoryComponent)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Radix.Foundation.Style (cn)
import Hydrogen.Radix.ScrollArea as ScrollArea
import Hydrogen.Radix.Toast as Toast
import Type.Proxy (Proxy(..))

story :: Story
story = { id: "inv-e", component }

type Slots =
  ( scrollArea :: ScrollArea.Slot Int
  , toast :: Toast.Slot Int
  )

_scrollArea :: Proxy "scrollArea"
_scrollArea = Proxy

_toast :: Proxy "toast"
_toast = Proxy

-- | Four skins, each a different class vocabulary on whatever parts a component has.
-- | These primitives have many parts, so a Skin carries a class string per slot the
-- | components use: `root`/`viewport`/`bar`/`thumb`/`corner` for ScrollArea and
-- | `wrapper`/`list`/`item`/`text`/`btn` for Toast. The strings are deliberately unrelated
-- | design systems — invariance must hold regardless of which one is on.
type Skin =
  { name :: String
  , root :: String     -- ScrollArea Root        / (Toast wrapper)
  , viewport :: String -- ScrollArea Viewport     / (Toast <ol>)
  , bar :: String      -- ScrollArea Scrollbar    / (Toast <li>)
  , thumb :: String    -- ScrollArea Thumb        / (Toast title+description)
  , corner :: String   -- ScrollArea Corner       / (Toast action+close)
  }

skins :: Array Skin
skins =
  [ { name: "unstyled", root: "", viewport: "", bar: "", thumb: "", corner: "" }
  , { name: "themes"
    , root: "rt-reset rt-ScrollAreaRoot"
    , viewport: "rt-ScrollAreaViewport"
    , bar: "rt-ScrollAreaScrollbar"
    , thumb: "rt-ScrollAreaThumb"
    , corner: "rt-ScrollAreaCorner"
    }
  , { name: "shadcn"
    , root: "relative overflow-hidden"
    , viewport: "h-full w-full rounded-[inherit]"
    , bar: "flex touch-none select-none transition-colors"
    , thumb: "relative flex-1 rounded-full bg-border"
    , corner: "bg-transparent"
    }
  , { name: "daisy"
    , root: "card"
    , viewport: "card-body"
    , bar: "scrollbar"
    , thumb: "scrollbar-thumb"
    , corner: "scrollbar-corner"
    }
  ]

component :: StoryComponent
component = H.mkComponent
  { initialState: const unit
  , render: const view
  , eval: H.mkEval H.defaultEval
  }

view :: H.ComponentHTML Void Slots Aff
view =
  HH.div
    [ HP.style "display:contents" ]
    [ group "ScrollArea" (mapWithIndex scrollAreaCell skins)
    , group "Toast" (mapWithIndex toastCell skins)
    ]
  where
  group name kids = HH.div [ HP.attr (HH.AttrName "data-invariance") name ] kids

  preset s kid = HH.div [ HP.attr (HH.AttrName "data-preset") s.name ] [ kid ]

  -- Stateful (Slot). `scrollbars=Vertical'` (the canonical single-bar, no-corner family),
  -- same fixed content/size across all skins so the content overflows and the thumb is
  -- sized < track. At rest the bar is mounted unconditionally (the component's only mode),
  -- so the structural surface — viewport overflow shorthand, data-orientation / data-state /
  -- the var-shaped inline styles, the thumb translate3d — is class-independent.
  scrollAreaCell i s = preset s $
    HH.slot_ _scrollArea i ScrollArea.component
      (ScrollArea.defaultInput
        { content =
            [ HH.div [] [ HH.text "Line one of the scrollable content." ]
            , HH.div [] [ HH.text "Line two of the scrollable content." ]
            , HH.div [] [ HH.text "Line three of the scrollable content." ]
            , HH.div [] [ HH.text "Line four of the scrollable content." ]
            , HH.div [] [ HH.text "Line five of the scrollable content." ]
            , HH.div [] [ HH.text "Line six of the scrollable content." ]
            , HH.div [] [ HH.text "Line seven of the scrollable content." ]
            , HH.div [] [ HH.text "Line eight of the scrollable content." ]
            ]
        , widthPx = 200
        , heightPx = 120
        , scrollbars = ScrollArea.Vertical'
        , style =
            { root: cn s.root
            , viewport: cn s.viewport
            , focusRing: cn ""
            , scrollbar: cn s.bar
            , thumb: cn s.thumb
            , corner: cn s.corner
            }
        })

  -- Stateful (Slot). Controlled `open=Just true` held open with `duration=Nothing` so no
  -- auto-dismiss timer ever fires — the deterministic at-rest open DOM. Same label / swipe
  -- direction / title / description / action / close across all skins; the SR-announce mirror
  -- is portaled to document.body (outside the [data-preset] subtree), so the gate never
  -- compares it. Only the per-part class lists vary between presets.
  toastCell i s = preset s $
    HH.slot_ _toast i Toast.component
      (Toast.defaultInput
        { open = Just true
        , defaultOpen = true
        , duration = Nothing
        , title = [ HH.text "Scheduled" ]
        , description = [ HH.text "Friday at 5pm" ]
        , action = [ HH.text "Undo" ]
        , altText = "Undo"
        , close = [ HH.text "×" ]
        , closeLabel = "Close"
        , announceText = "Notification Scheduled Friday at 5pm Undo"
        , style =
            { viewport: cn s.viewport
            , wrapper: cn s.root
            , root: cn s.bar
            , title: cn s.thumb
            , description: cn s.thumb
            , action: cn s.corner
            , close: cn s.corner
            }
        })
