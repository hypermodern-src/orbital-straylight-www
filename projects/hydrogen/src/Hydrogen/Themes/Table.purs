-- | Hydrogen.Themes.Table — `table.tsx`: the Radix Themes data table.
-- |
-- | `Table.Root` is a `<div class="rt-TableRoot">` (carrying the size/variant —
-- | defaults size 2 / variant ghost) wrapping a `<ScrollArea>` whose viewport holds
-- | the actual `<table class="rt-TableRootTable">`. We reproduce the AT-REST DOM of
-- | the underlying Radix `ScrollArea` primitive (type="hover"): with no overflow and
-- | no pointer hover the scrollbars/corner are unmounted (`<Presence present=false>`),
-- | so the tree is Root > ScrollAreaRoot > (injected <style> + ScrollAreaViewport >
-- | content-div > table) + ScrollAreaViewportFocusRing.
-- |
-- | thead/tbody/tr/th/td carry rt-Table{Header,Body,Row,Cell,…}; header cells add
-- | rt-TableColumnHeaderCell (scope="col") / rt-TableRowHeaderCell (scope="row").
module Hydrogen.Themes.Table
  ( tableRoot
  , tableHeader
  , tableBody
  , tableRow
  , tableColumnHeaderCell
  , tableRowHeaderCell
  , tableCell
  ) where

import Prelude

import Halogen.HTML as HH
import Hydrogen.Themes.Prop (Prop(..), attrs, el)

-- | `Table.Root` — the outer div + ScrollArea + the `<table>`. Defaults size 2 /
-- | variant ghost (last-wins, so caller props override).
tableRoot :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
tableRoot props children =
  HH.div
    (attrs [ "rt-TableRoot" ] ([ Size "2", Variant "ghost" ] <> props))
    [ scrollAreaRoot
        [ scrollAreaViewportStyle
        , scrollAreaViewport
            [ scrollAreaContent
                [ el "table" [ "rt-TableRootTable" ] [] children ]
            ]
        , focusRing
        ]
    ]
  where
  scrollAreaRoot =
    el "div" [ "rt-ScrollAreaRoot" ]
      [ RawAttr "dir" "ltr"
      , StyleProp "position" "relative"
      , StyleProp "--radix-scroll-area-corner-width" "0px"
      , StyleProp "--radix-scroll-area-corner-height" "0px"
      ]
  scrollAreaViewport =
    el "div" [ "rt-ScrollAreaViewport" ]
      [ DataAttr "radix-scroll-area-viewport" ""
      , StyleProp "overflow-x" "hidden"
      , StyleProp "overflow-y" "hidden"
      ]
  scrollAreaContent =
    el "div" []
      [ StyleProp "min-width" "100%"
      , StyleProp "display" "table"
      ]
  focusRing = el "div" [ "rt-ScrollAreaViewportFocusRing" ] [] []
  scrollAreaViewportStyle =
    HH.element (HH.ElemName "style") []
      [ HH.text "[data-radix-scroll-area-viewport]{scrollbar-width:none;-ms-overflow-style:none;-webkit-overflow-scrolling:touch;}[data-radix-scroll-area-viewport]::-webkit-scrollbar{display:none}" ]

-- | `Table.Header` — `<thead class="rt-TableHeader">`.
tableHeader :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
tableHeader = el "thead" [ "rt-TableHeader" ]

-- | `Table.Body` — `<tbody class="rt-TableBody">`.
tableBody :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
tableBody = el "tbody" [ "rt-TableBody" ]

-- | `Table.Row` — `<tr class="rt-TableRow">`. Carries the `align` prop (rt-r-va).
tableRow :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
tableRow = el "tr" [ "rt-TableRow" ]

-- | `Table.ColumnHeaderCell` — `<th class="rt-TableCell rt-TableColumnHeaderCell" scope="col">`.
tableColumnHeaderCell :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
tableColumnHeaderCell props =
  el "th" [ "rt-TableCell", "rt-TableColumnHeaderCell" ] ([ RawAttr "scope" "col" ] <> props)

-- | `Table.RowHeaderCell` — `<th class="rt-TableCell rt-TableRowHeaderCell" scope="row">`.
tableRowHeaderCell :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
tableRowHeaderCell props =
  el "th" [ "rt-TableCell", "rt-TableRowHeaderCell" ] ([ RawAttr "scope" "row" ] <> props)

-- | `Table.Cell` — `<td class="rt-TableCell">`.
tableCell :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
tableCell = el "td" [ "rt-TableCell" ]
