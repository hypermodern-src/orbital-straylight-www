-- | Hydrogen.Themes.Select — the ANCHORED single-select listbox (Bucket B,
-- | floating family; built on the same anchoring primitive as Popover).
-- |
-- | Upstream: radix-ui-themes `select.tsx` / `select.props.tsx` / `select.css`.
-- | A `<button class="rt-reset rt-SelectTrigger rt-r-size-2 rt-variant-surface">`
-- | (role=combobox, aria-expanded) holds a `rt-SelectTriggerInner` span showing the
-- | SELECTED item's label plus a `rt-SelectIcon` chevron SVG. Clicking it anchors a
-- | `rt-reset rt-PopperContent rt-SelectContent rt-r-size-2 rt-variant-solid`
-- | listbox (role=listbox) below the trigger (Popover anchoring: measure the
-- | trigger's viewport rect, place a `position: fixed` panel at `bottom + 4`,
-- | align start). Each option is a `rt-reset rt-SelectItem` (role=option,
-- | aria-selected); the currently-selected one carries a `rt-SelectItemIndicator`
-- | check SVG.
-- |
-- | SELECTION STATE — this is the distinguishing behaviour vs Popover:
-- |   * `selected :: String` (the value) drives the trigger's inner text and the
-- |     per-item `aria-selected` + indicator. Clicking an item (or pressing Enter on
-- |     the highlighted one) sets `selected` to that value AND closes the listbox,
-- |     so the trigger text updates to the chosen label.
-- |   * Keyboard: ArrowDown / ArrowUp move a `highlighted` cursor (rendered as
-- |     `data-highlighted` — upstream's solid-variant active style), Enter commits
-- |     it, Escape closes. An outside click closes (document click + containsTarget).
-- |
-- | PORTAL pattern (copied from Popover): the listbox is rendered UNCONDITIONALLY
-- | (stable VDOM child) and hidden with `display: none` when closed; `portalize`
-- | adopts it to the shared body container via `afterFrame` on init + each open.
module Hydrogen.Themes.Select
  ( Input
  , Item
  , component
  ) where

import Prelude

import Data.Array (findIndex, index, length, mapWithIndex)
import Data.Maybe (Maybe(..), fromMaybe)
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.Query.Event (eventListener)
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

-- | One selectable option: the committed `value` and the displayed `label`.
type Item =
  { value :: String
  , label :: String
  }

-- | The options + which value starts selected.
type Input =
  { items :: Array Item
  , selected :: String
  }

type State =
  { input :: Input
  , open :: Boolean
  , selected :: String
  , highlighted :: Int
  , top :: Number
  , left :: Number
  }

data Action
  = Initialize
  | ToggleD
  | CloseD
  | Choose String
  | KeyDown KE.KeyboardEvent
  | DocClick Event.Event

triggerRef :: H.RefLabel
triggerRef = H.RefLabel "select-trigger"

panelRef :: H.RefLabel
panelRef = H.RefLabel "select-panel"

portalRoot :: String
portalRoot = "hydrogen-portal-root"

-- | Upstream's Select content sideOffset is 4 (popover.tsx defaults to 8).
sideOffset :: Number
sideOffset = 4.0

svgNS :: HH.Namespace
svgNS = HH.Namespace "http://www.w3.org/2000/svg"

component :: forall q o m. MonadEffect m => H.Component q Input o m
component =
  H.mkComponent
    { initialState: \input ->
        { input
        , open: false
        , selected: input.selected
        , highlighted: selectedIndex input.items input.selected
        , top: 0.0
        , left: 0.0
        }
    , render
    , eval: H.mkEval H.defaultEval
        { handleAction = handleAction
        , initialize = Just Initialize
        }
    }

-- | Index of the selected value within the items (0 if not found).
selectedIndex :: Array Item -> String -> Int
selectedIndex items value =
  fromMaybe 0 (findIndex (\i -> i.value == value) items)

-- | The label to show for the currently-selected value (the value itself as a
-- | fallback, so the trigger never goes blank if state drifts).
selectedLabel :: State -> String
selectedLabel st =
  case findIndex (\i -> i.value == st.selected) st.input.items of
    Just ix -> case index st.input.items ix of
      Just it -> it.label
      Nothing -> st.selected
    Nothing -> st.selected

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
        r <- liftEffect (Portal.anchorRect (HTMLElement.toElement he))
        -- opening starts the highlight on the currently-selected option.
        H.modify_ \s -> s
          { open = true
          , top = r.bottom + sideOffset
          , left = r.left
          , highlighted = selectedIndex s.input.items s.selected
          }
        portalize

  CloseD ->
    H.modify_ _ { open = false }

  Choose value ->
    -- commit the chosen value (updates the trigger text) and close.
    H.modify_ \s -> s
      { selected = value
      , highlighted = selectedIndex s.input.items value
      , open = false
      }

  KeyDown ke -> do
    st <- H.get
    let key = KE.key ke
    if not st.open then pure unit
    else case key of
      "Escape" -> handleAction CloseD
      "ArrowDown" -> do
        liftEffect (Event.preventDefault (KE.toEvent ke))
        let n = length st.input.items
        when (n > 0) $
          H.modify_ \s -> s { highlighted = clampIndex (s.highlighted + 1) n }
      "ArrowUp" -> do
        liftEffect (Event.preventDefault (KE.toEvent ke))
        let n = length st.input.items
        when (n > 0) $
          H.modify_ \s -> s { highlighted = clampIndex (s.highlighted - 1) n }
      "Enter" -> do
        liftEffect (Event.preventDefault (KE.toEvent ke))
        case index st.input.items st.highlighted of
          Just it -> handleAction (Choose it.value)
          Nothing -> pure unit
      _ -> pure unit

  DocClick ev -> do
    st <- H.get
    when st.open do
      inPanel <- refContains panelRef ev
      inTrigger <- refContains triggerRef ev
      when (not inPanel && not inTrigger) (handleAction CloseD)

-- | Clamp an index into [0, n-1] (n assumed > 0).
clampIndex :: Int -> Int -> Int
clampIndex i n
  | i < 0 = 0
  | i >= n = n - 1
  | otherwise = i

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
      ( attrs [ "rt-reset", "rt-SelectTrigger" ] [ Size "2", Variant "surface" ]
          <>
            [ HP.ref triggerRef
            , HP.type_ HP.ButtonButton
            , HP.attr (HH.AttrName "role") "combobox"
            , HP.attr (HH.AttrName "aria-haspopup") "listbox"
            , HP.attr (HH.AttrName "aria-expanded") (if st.open then "true" else "false")
            , HP.attr (HH.AttrName "aria-autocomplete") "none"
            , HP.attr (HH.AttrName "data-state") (dataState st.open)
            , HE.onClick (\_ -> ToggleD)
            ]
      )
      [ HH.span
          [ HP.class_ (HH.ClassName "rt-SelectTriggerInner") ]
          [ HH.text (selectedLabel st) ]
      , chevronIcon
      ]

  panel =
    HH.div
      ( attrs [ "rt-reset", "rt-PopperContent", "rt-SelectContent" ] [ Size "2", Variant "solid" ]
          <>
            [ HP.ref panelRef
            , HP.attr (HH.AttrName "role") "listbox"
            , HP.attr (HH.AttrName "data-state") (dataState st.open)
            , HP.attr (HH.AttrName "data-side") "bottom"
            , HP.attr (HH.AttrName "data-align") "start"
            , HP.style (positionStyle st)
            ]
      )
      (mapWithIndex (renderItem st) st.input.items)

  renderItem state ix item =
    let
      isSelected = item.value == state.selected
      isHighlighted = ix == state.highlighted
    in
      HH.div
        ( [ HP.class_ (HH.ClassName "rt-reset rt-SelectItem")
          , HP.attr (HH.AttrName "role") "option"
          , HP.attr (HH.AttrName "aria-selected") (if isSelected then "true" else "false")
          , HP.attr (HH.AttrName "data-value") item.value
          , HP.tabIndex (-1)
          -- click commits the value, updating the trigger text + closing.
          , HE.onClick (\_ -> Choose item.value)
          ]
            <> (if isHighlighted then [ HP.attr (HH.AttrName "data-highlighted") "true" ] else [])
        )
        ( (if isSelected then [ checkIndicator ] else [])
            <> [ HH.span [ HP.class_ (HH.ClassName "rt-SelectItemText") ] [ HH.text item.label ] ]
        )

-- | The trigger's chevron (ChevronDownIcon, class rt-SelectIcon).
chevronIcon :: forall w i. HH.HTML w i
chevronIcon =
  HH.elementNS svgNS (HH.ElemName "svg")
    [ HP.attr (HH.AttrName "class") "rt-SelectIcon"
    , HP.attr (HH.AttrName "width") "9"
    , HP.attr (HH.AttrName "height") "9"
    , HP.attr (HH.AttrName "viewBox") "0 0 9 9"
    , HP.attr (HH.AttrName "fill") "currentcolor"
    , HP.attr (HH.AttrName "xmlns") "http://www.w3.org/2000/svg"
    ]
    [ HH.elementNS svgNS (HH.ElemName "path")
        [ HP.attr (HH.AttrName "d")
            "M0.135232 3.15803C0.324102 2.95657 0.640521 2.94637 0.841971 3.13523L4.5 6.56464L8.158 3.13523C8.3595 2.94637 8.6759 2.95657 8.8648 3.15803C9.0536 3.35949 9.0434 3.67591 8.842 3.86477L4.84197 7.6148C4.64964 7.7951 4.35036 7.7951 4.15803 7.6148L0.158031 3.86477C-0.0434285 3.67591 -0.0536285 3.35949 0.135232 3.15803Z"
        ]
        []
    ]

-- | The selected-item check (ThickCheckIcon) wrapped in rt-SelectItemIndicator.
checkIndicator :: forall w i. HH.HTML w i
checkIndicator =
  HH.span
    [ HP.class_ (HH.ClassName "rt-SelectItemIndicator") ]
    [ HH.elementNS svgNS (HH.ElemName "svg")
        [ HP.attr (HH.AttrName "class") "rt-SelectItemIndicatorIcon"
        , HP.attr (HH.AttrName "width") "9"
        , HP.attr (HH.AttrName "height") "9"
        , HP.attr (HH.AttrName "viewBox") "0 0 9 9"
        , HP.attr (HH.AttrName "fill") "currentcolor"
        , HP.attr (HH.AttrName "xmlns") "http://www.w3.org/2000/svg"
        ]
        [ HH.elementNS svgNS (HH.ElemName "path")
            [ HP.attr (HH.AttrName "fill-rule") "evenodd"
            , HP.attr (HH.AttrName "clip-rule") "evenodd"
            , HP.attr (HH.AttrName "d")
                "M8.53547 0.62293C8.88226 0.849446 8.97976 1.3142 8.75325 1.66099L4.5083 8.1599C4.38833 8.34356 4.19397 8.4655 3.9764 8.49358C3.75883 8.52167 3.53987 8.45309 3.3772 8.30591L0.616113 5.80777C0.308959 5.52987 0.285246 5.05559 0.563148 4.74844C0.84105 4.44128 1.31533 4.41757 1.62249 4.69547L3.73256 6.60459L7.49741 0.840706C7.72393 0.493916 8.18868 0.396414 8.53547 0.62293Z"
            ]
            []
        ]
    ]

positionStyle :: State -> String
positionStyle st =
  if st.open then
    "position: fixed; top: " <> show st.top <> "px; left: " <> show st.left <> "px"
  else
    "display: none"
