-- | Hydrogen.Themes.Tabs — the styled Radix Themes Tabs.
-- |
-- | Mirrors `tabs.tsx`:
-- |   * `Tabs.Root`    → `<div class="rt-TabsRoot">` (the unstyled primitive's
-- |     `data-orientation` / `dir` ride along: defaults `horizontal` / `ltr`).
-- |   * `Tabs.List`    → `<div role="tablist" aria-orientation="horizontal"
-- |     class="rt-BaseTabList rt-TabsList">` carrying the size default (2) from
-- |     `_internal/base-tab-list.props.ts`. With no `color` prop the React render
-- |     emits `data-accent-color={undefined}` (no attribute), so we omit it too.
-- |   * `Tabs.Trigger` → `<button type="button" role="tab"
-- |     class="rt-reset rt-BaseTabListTrigger rt-TabsTrigger">` holding the visible
-- |     inner span + the hidden (bold) measuring span. `data-state` is `active` for
-- |     the selected tab, `inactive` otherwise — that drives the indicator `::before`
-- |     and the active font-weight, so it is pixel-load-bearing.
-- |
-- | This is the AT-REST render used for the pixel goldens: the roving-focus group
-- | (tabindex shuffling, focus handlers) and live activation are a later layer over
-- | the ported primitive; only the rendered DOM + classes are reproduced here.
module Hydrogen.Themes.Tabs
  ( tabsRoot
  , tabsList
  , tabsTrigger
  ) where

import Prelude

import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Themes.Prop (Prop(..), el)

-- | `tabsRoot [] [ tabsList … ]` → `<div class="rt-TabsRoot" data-orientation…>`.
tabsRoot :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
tabsRoot props =
  el "div" [ "rt-TabsRoot" ]
    ( [ DataAttr "orientation" "horizontal"
      , RawAttr "dir" "ltr"
      ] <> props
    )

-- | `tabsList [] [ tabsTrigger … ]`. Size default 2 (last-wins over caller props).
tabsList :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
tabsList props =
  el "div" [ "rt-BaseTabList", "rt-TabsList" ]
    ( [ Size "2"
      , RawAttr "role" "tablist"
      , RawAttr "aria-orientation" "horizontal"
      ] <> props
    )

-- | `tabsTrigger active [] [ HH.text "Account" ]`. `active` selects the
-- | `data-state=active|inactive` (and the matching aria-selected).
tabsTrigger :: forall w i. Boolean -> Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
tabsTrigger active props children =
  el "button" [ "rt-reset", "rt-BaseTabListTrigger", "rt-TabsTrigger" ]
    ( [ RawAttr "type" "button"
      , RawAttr "role" "tab"
      , RawAttr "aria-selected" (if active then "true" else "false")
      , DataAttr "state" (if active then "active" else "inactive")
      , DataAttr "orientation" "horizontal"
      , RawAttr "tabindex" (if active then "0" else "-1")
      ] <> props
    )
    [ HH.span
        [ HP.class_ (HH.ClassName "rt-BaseTabListTriggerInner rt-TabsTriggerInner") ]
        children
    , HH.span
        [ HP.class_ (HH.ClassName "rt-BaseTabListTriggerInnerHidden rt-TabsTriggerInnerHidden") ]
        children
    ]
