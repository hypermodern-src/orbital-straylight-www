-- | Hydrogen.Themes.DropdownMenu — a CLICK-triggered anchored menu (Bucket B).
-- |
-- | Mirrors upstream `dropdown-menu.tsx` (+ `_internal/base-menu.*`). The trigger
-- | is a real `<button>`; clicking it toggles an anchored menu that uses the same
-- | floating machinery as Popover — measure the trigger's viewport rect
-- | (`Portal.anchorRect`), place a `position: fixed` panel below it (align=start,
-- | sideOffset=4 — upstream's DropdownMenu.Content defaults). The panel is PORTALED
-- | into the shared body-level `.radix-themes` container (re-asserted on
-- | `afterFrame`) so its fixed position escapes ancestor containing blocks.
-- |
-- | DOM mirrors upstream:
-- |   * Content: `rt-reset rt-PopperContent rt-BaseMenuContent rt-DropdownMenuContent
-- |     rt-r-size-2`, `role="menu"`, `data-state` open/closed, `data-side=bottom`,
-- |     `data-align=start`.
-- |   * Item: `rt-reset rt-BaseMenuItem rt-DropdownMenuItem`, `role="menuitem"`,
-- |     `tabindex=-1`; the currently-highlighted item carries `data-highlighted=""`.
-- |
-- | KEYBOARD (the distinguishing behaviour): while OPEN, a DOCUMENT keydown handler
-- | routes the roving highlight — ArrowDown/ArrowUp move `highlighted :: Int` with
-- | wraparound (and `preventDefault` so the page doesn't scroll), Enter activates the
-- | highlighted item (closes), Escape closes. A mouse click on an item also activates
-- | it; an OUTSIDE click closes (document click + `Portal.containsTarget` over the
-- | panel and the trigger — the trigger's own onClick runs first in the bubble phase).
-- | On open the highlight resets to "nothing" (-1) so the first ArrowDown lands on 0.
module Hydrogen.Themes.DropdownMenu
  ( Input
  , component
  ) where

import Prelude

import Data.Array (length, mapWithIndex)
import Data.Maybe (Maybe(..))
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.Query.Event (eventListener)
import Hydrogen.Themes.Floating (measureSize, panelStyle)
import Hydrogen.Themes.Prop (Prop(..), attrs)
import Web.Event.Event as Event
import Web.HTML (window)
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.Window as Window
import Web.UIEvent.KeyboardEvent as KE
import Web.UIEvent.KeyboardEvent.EventTypes as KET
import Web.UIEvent.MouseEvent.EventTypes as MET

import Hydrogen.Themes.Portal as Portal

-- | The trigger label + the menu items (a label per `<menuitem>`).
type Input =
  { triggerLabel :: String
  , items :: Array String
  }

type State =
  { input :: Input
  , open :: Boolean
  , top :: Number
  , left :: Number
  , side :: String
  , highlighted :: Int -- -1 = nothing highlighted yet
  }

data Action
  = Initialize
  | ToggleD
  | CloseD
  | Activate Int
  | KeyDown KE.KeyboardEvent
  | DocClick Event.Event

triggerRef :: H.RefLabel
triggerRef = H.RefLabel "dropdown-trigger"

panelRef :: H.RefLabel
panelRef = H.RefLabel "dropdown-panel"

portalRoot :: String
portalRoot = "hydrogen-portal-root"

sideOffset :: Number
sideOffset = 4.0

-- | Prefer below the trigger, align start; flip up / shift in near a viewport edge.
placement :: Portal.Anchored
placement = { preferTop: false, align: "start", offset: sideOffset, pad: 8.0 }

component :: forall q o m. MonadEffect m => H.Component q Input o m
component =
  H.mkComponent
    { initialState: \input -> { input, open: false, top: 0.0, left: 0.0, side: "bottom", highlighted: -1 }
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
    -- outside-click close: a document click listener (bubble phase) fires AFTER the
    -- trigger's own onClick, so by the time DocClick evaluates the toggle is applied.
    void $ H.subscribe $ eventListener MET.click target (Just <<< DocClick)
    portalize

  ToggleD -> do
    st <- H.get
    if st.open then handleAction CloseD
    else H.getHTMLElementRef triggerRef >>= case _ of
      Nothing -> pure unit
      Just he -> do
        anchor <- liftEffect (Portal.anchorRect (HTMLElement.toElement he))
        panel <- measureSize panelRef
        vp <- liftEffect Portal.viewportSize
        let p = Portal.solveAnchored placement anchor panel vp
        H.modify_ _ { open = true, top = p.top, left = p.left, side = p.side, highlighted = -1 }
        portalize

  CloseD ->
    H.modify_ _ { open = false, highlighted = -1 }

  Activate _ ->
    -- click/Enter on an item: close the menu (a richer port raises an output here).
    handleAction CloseD

  KeyDown ke -> do
    st <- H.get
    when st.open do
      let
        n = length st.input.items
        key = KE.key ke
      when (n > 0) case key of
        "ArrowDown" -> do
          liftEffect (Event.preventDefault (KE.toEvent ke))
          H.modify_ \s -> s { highlighted = wrap n (s.highlighted + 1) }
        "ArrowUp" -> do
          liftEffect (Event.preventDefault (KE.toEvent ke))
          H.modify_ \s -> s { highlighted = wrap n (s.highlighted - 1) }
        "Enter" -> do
          liftEffect (Event.preventDefault (KE.toEvent ke))
          when (st.highlighted >= 0) (handleAction (Activate st.highlighted))
        _ -> pure unit
      when (key == "Escape") (handleAction CloseD)

  DocClick ev -> do
    st <- H.get
    when st.open do
      inPanel <- refContains panelRef ev
      inTrigger <- refContains triggerRef ev
      when (not inPanel && not inTrigger) (handleAction CloseD)

-- | Wrap an index into [0, n) (handles the -1→n-1 ArrowUp-from-nothing case too).
wrap :: Int -> Int -> Int
wrap n i = ((i `mod` n) + n) `mod` n

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
    [ trigger, panel ]
  where
  dataState b = if b then "open" else "closed"

  trigger =
    HH.button
      ( attrs [ "rt-reset", "rt-BaseButton", "rt-Button" ] [ Variant "soft", Size "2" ]
          <> [ HP.ref triggerRef
             , HP.type_ HP.ButtonButton
             , HP.attr (HH.AttrName "aria-haspopup") "menu"
             , HP.attr (HH.AttrName "aria-expanded") (if st.open then "true" else "false")
             , HP.attr (HH.AttrName "data-state") (dataState st.open)
             , HE.onClick (\_ -> ToggleD)
             ]
      )
      [ HH.text st.input.triggerLabel ]

  -- Content: `rt-reset rt-PopperContent rt-BaseMenuContent rt-DropdownMenuContent
  -- rt-r-size-2`. Always mounted (so the adopted node is patched in place, never
  -- re-inserted); `display:none` when closed.
  panel =
    HH.div
      ( attrs [ "rt-reset", "rt-PopperContent", "rt-BaseMenuContent", "rt-DropdownMenuContent" ] [ Size "2" ]
          <>
            [ HP.ref panelRef
            , HP.attr (HH.AttrName "role") "menu"
            , HP.attr (HH.AttrName "data-state") (dataState st.open)
            , HP.attr (HH.AttrName "data-side") st.side
            , HP.attr (HH.AttrName "data-align") "start"
            , HP.style (positionStyle st)
            ]
      )
      (mapWithIndex (item st.highlighted) st.input.items)

  item :: Int -> Int -> String -> H.ComponentHTML Action () m
  item hi i label =
    HH.div
      ( [ HP.class_ (HH.ClassName "rt-reset rt-BaseMenuItem rt-DropdownMenuItem")
        , HP.attr (HH.AttrName "role") "menuitem"
        , HP.tabIndex (-1)
        , HE.onClick (\_ -> Activate i)
        ]
          <> (if hi == i then [ HP.attr (HH.AttrName "data-highlighted") "" ] else [])
      )
      [ HH.text label ]

positionStyle :: State -> String
positionStyle st = panelStyle st.open st.top st.left ""
