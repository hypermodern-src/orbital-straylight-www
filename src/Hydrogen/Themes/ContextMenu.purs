-- | Hydrogen.Themes.ContextMenu — the RIGHT-CLICK menu (Bucket B, floating family).
-- |
-- | Ported from radix-ui/themes `context-menu.tsx` / `_internal/base-menu.props.ts`
-- | / `_internal/base-menu.css`. Structurally this is the same menu as DropdownMenu
-- | (`rt-PopperContent rt-BaseMenuContent` + `rt-BaseMenuViewport` + `rt-BaseMenuItem`
-- | rows, keyboard-navigated via `data-highlighted`), but with the ContextMenu skin
-- | (`rt-ContextMenuContent` / `rt-ContextMenuViewport` / `rt-ContextMenuItem`) and a
-- | fundamentally different opening gesture:
-- |
-- |   * The KEY DIFFERENCE from every other floating overlay: it is NOT anchored to a
-- |     trigger element. It opens on a `contextmenu` event (a right-click / long-press)
-- |     over a target REGION, `preventDefault`s the native browser menu, and positions
-- |     the panel AT THE CURSOR (event.clientX / event.clientY) as a `position: fixed`
-- |     layer. So there is no `Portal.anchorRect`; placement reads clientX/clientY off
-- |     the MouseEvent directly. A plain LEFT click over the region does nothing.
-- |   * NON-modal, like Popover: no scroll-lock, no backdrop. Closes on Escape
-- |     (document keydown), on an OUTSIDE click (document click + `Portal.containsTarget`
-- |     over the panel), and after selecting an item.
-- |   * Keyboard nav matches the base menu: ArrowDown / ArrowUp move the highlight
-- |     (`data-highlighted` on the active row), Enter activates it, Escape closes.
-- |   * Panel is PORTALED to the body `.radix-themes` container (afterFrame re-adopt),
-- |     so its fixed position escapes ancestor containing blocks. The panel is rendered
-- |     UNCONDITIONALLY (stable VDOM child, `display: none` while closed) — never
-- |     conditionally, or Halogen would removeChild from the wrong parent.
-- |
-- | Defaults mirror upstream: `size = '2'`, `variant = 'solid'`.
module Hydrogen.Themes.ContextMenu
  ( Input
  , component
  ) where

import Prelude

import Data.Array (mapWithIndex, index, length)
import Data.Int (toNumber)
import Data.Maybe (Maybe(..), fromMaybe)
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.Query.Event (eventListener)
import Hydrogen.Themes.Prop (Prop(..), attrs)
import Web.Event.Event (EventType(..))
import Web.Event.Event as Event
import Web.HTML (window)
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.Window as Window
import Web.UIEvent.KeyboardEvent as KE
import Web.UIEvent.KeyboardEvent.EventTypes as KET
import Web.UIEvent.MouseEvent as ME
import Web.UIEvent.MouseEvent.EventTypes as MET

import Hydrogen.Themes.Portal as Portal

-- | A label for the styled "right-click here" region + the menu rows.
type Input =
  { regionLabel :: String
  , items :: Array String
  }

type State =
  { input :: Input
  , open :: Boolean
  , top :: Number
  , left :: Number
  , highlight :: Int -- index of the currently keyboard-highlighted row (-1 = none)
  }

data Action
  = Initialize
  | OpenAt Event.Event -- a `contextmenu` (right-click) over the region
  | CloseD
  | SelectIdx Int
  | HoverIdx Int
  | KeyDown KE.KeyboardEvent
  | DocClick Event.Event

panelRef :: H.RefLabel
panelRef = H.RefLabel "contextmenu-panel"

portalRoot :: String
portalRoot = "hydrogen-portal-root"

-- | The native `contextmenu` event type (Web.UIEvent.MouseEvent.EventTypes omits it).
contextmenu :: EventType
contextmenu = EventType "contextmenu"

component :: forall q o m. MonadEffect m => H.Component q Input o m
component =
  H.mkComponent
    { initialState: \input -> { input, open: false, top: 0.0, left: 0.0, highlight: -1 }
    , render
    , eval: H.mkEval H.defaultEval
        { handleAction = handleAction
        , initialize = Just Initialize
        }
    }

handleAction :: forall o m. MonadEffect m => Action -> H.HalogenM State Action () o m Unit
handleAction = case _ of
  Initialize -> do
    doc <- liftEffect (window >>= Window.document)
    let target = HTMLDocument.toEventTarget doc
    void $ H.subscribe $ eventListener KET.keydown target (\e -> KeyDown <$> KE.fromEvent e)
    -- outside-click close: document click (bubble phase).
    void $ H.subscribe $ eventListener MET.click target (Just <<< DocClick)
    portalize

  -- Right-click over the region: suppress the native browser menu, read the pointer
  -- position off the MouseEvent and place a fixed panel right there.
  OpenAt ev -> do
    liftEffect (Event.preventDefault ev)
    case ME.fromEvent ev of
      Nothing -> pure unit
      Just me -> do
        H.modify_ _
          { open = true
          , top = toNumber (ME.clientY me)
          , left = toNumber (ME.clientX me)
          , highlight = -1
          }
        portalize

  CloseD ->
    H.modify_ _ { open = false, highlight = -1 }

  SelectIdx _ ->
    -- selecting a row dismisses the menu (the action it triggers is the caller's job).
    handleAction CloseD

  -- highlight changes re-render, and Halogen re-parents the adopted panel back into
  -- the component root on patch — so re-assert the body-mount after each (the menu
  -- opens UNDER the cursor, so an item is hovered immediately on open).
  HoverIdx i -> do
    H.modify_ _ { highlight = i }
    portalize

  KeyDown ke -> do
    st <- H.get
    when st.open case KE.key ke of
      "Escape" -> handleAction CloseD
      "ArrowDown" -> do
        liftEffect (Event.preventDefault (KE.toEvent ke))
        let n = length st.input.items
        when (n > 0) do
          H.modify_ _ { highlight = (st.highlight + 1) `mod` n }
          portalize
      "ArrowUp" -> do
        liftEffect (Event.preventDefault (KE.toEvent ke))
        let n = length st.input.items
        when (n > 0) do
          H.modify_ _ { highlight = (st.highlight - 1 + n) `mod` n }
          portalize
      "Enter" ->
        when (st.highlight >= 0) (handleAction (SelectIdx st.highlight))
      _ -> pure unit

  DocClick ev -> do
    st <- H.get
    when st.open do
      inPanel <- refContains panelRef ev
      when (not inPanel) (handleAction CloseD)

refContains :: forall o m. MonadEffect m => H.RefLabel -> Event.Event -> H.HalogenM State Action () o m Boolean
refContains ref ev =
  H.getHTMLElementRef ref >>= case _ of
    Nothing -> pure false
    Just he -> liftEffect (Portal.containsTarget (HTMLElement.toElement he) ev)

portalize :: forall o m. MonadEffect m => H.HalogenM State Action () o m Unit
portalize = do
  container <- liftEffect (Portal.ensureContainer portalRoot)
  H.getHTMLElementRef panelRef >>= case _ of
    Just he -> liftEffect (Portal.afterFrame (Portal.adopt container (HTMLElement.toElement he)))
    Nothing -> pure unit

render :: forall m. State -> H.ComponentHTML Action () m
render st =
  HH.div_
    [ region, panel ]
  where
  dataState b = if b then "open" else "closed"

  -- The styled target region. A right-click (contextmenu) opens the menu; a left
  -- click does nothing.
  region =
    HH.div
      ( [ HP.class_ (HH.ClassName "rt-ContextMenuTriggerRegion")
        , HP.attr (HH.AttrName "data-state") (dataState st.open)
        , HP.style "display: flex; align-items: center; justify-content: center; height: 160px; border: 1px dashed var(--gray-a7); border-radius: var(--radius-3); user-select: none; cursor: context-menu"
        , HE.handler contextmenu OpenAt
        ]
      )
      [ HH.span (attrs [ "rt-Text" ] [ Size "2" ]) [ HH.text st.input.regionLabel ] ]

  panel =
    HH.div
      ( attrs
          [ "rt-PopperContent", "rt-BaseMenuContent", "rt-ContextMenuContent" ]
          [ Size "2", Variant "solid" ]
          <>
            [ HP.ref panelRef
            , HP.attr (HH.AttrName "role") "menu"
            , HP.attr (HH.AttrName "data-state") (dataState st.open)
            , HP.attr (HH.AttrName "data-side") "right"
            , HP.attr (HH.AttrName "data-align") "start"
            , HP.style (positionStyle st)
            ]
      )
      [ HH.div
          (attrs [ "rt-BaseMenuViewport", "rt-ContextMenuViewport" ] [])
          (mapWithIndex (renderItem st) st.input.items)
      ]

renderItem :: forall m. State -> Int -> String -> H.ComponentHTML Action () m
renderItem st i label =
  HH.div
    ( attrs [ "rt-reset", "rt-BaseMenuItem", "rt-ContextMenuItem" ] []
        <>
          [ HP.attr (HH.AttrName "role") "menuitem"
          , HP.attr (HH.AttrName "tabindex") "-1"
          ]
        <> (if st.highlight == i then [ HP.attr (HH.AttrName "data-highlighted") "" ] else [])
        <>
          [ HE.onMouseEnter (\_ -> HoverIdx i)
          , HE.onClick (\_ -> SelectIdx i)
          ]
    )
    [ HH.text label ]

positionStyle :: State -> String
positionStyle st =
  if st.open then
    "position: fixed; top: " <> show st.top <> "px; left: " <> show st.left <> "px"
  else
    "display: none"

-- avoid unused-import warnings for helpers kept for parity with the menu family
_unusedIndexFromMaybe :: Array String -> Int -> String
_unusedIndexFromMaybe xs i = fromMaybe "" (index xs i)
