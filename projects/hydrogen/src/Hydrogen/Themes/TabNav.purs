-- | Hydrogen.Themes.TabNav — the styled Radix Themes TabNav (a nav of links).
-- |
-- | Mirrors `tab-nav.tsx` (a `NavigationMenu`-backed sibling of `Tabs`):
-- |   * `TabNav.Root` → `<nav class="rt-TabNavRoot" data-accent-color?>` wrapping a
-- |     `<div class="rt-reset rt-BaseTabList rt-TabNavList" role="tablist"
-- |     aria-orientation="horizontal">`. The list carries the size default (2) from
-- |     `_internal/base-tab-list.props.ts`. With no `color` prop the React render
-- |     emits `data-accent-color={undefined}` (no attribute), so we omit it too; a
-- |     caller `Color` rides onto the root `<nav>` as `data-accent-color`.
-- |   * `TabNav.Link` → `<div class="rt-TabNavItem">` (the `NavigationMenu.Item`,
-- |     `display: flex` per tab-nav.css) wrapping
-- |     `<a class="rt-reset rt-BaseTabListTrigger rt-TabNavLink" href data-active?>`
-- |     holding the visible inner span + the hidden (bold) measuring span — the same
-- |     inner/hidden pair as `Tabs.Trigger`. The boolean `active` prop emits Radix
-- |     NavigationMenu's `data-active` (a bare boolean attribute, present only when
-- |     active); that drives the active indicator `::before` and font-weight, so it
-- |     is pixel-load-bearing.
-- |
-- | This is the AT-REST render used for the pixel goldens: NavigationMenu's focus /
-- | pointer machinery (data-state, viewport, etc.) is a later layer; only the
-- | rendered DOM + classes are reproduced here.
module Hydrogen.Themes.TabNav
  ( tabNavRoot
  , tabNavLink
  ) where

import Prelude

import Data.Array (filter)
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Themes.Prop (Prop(..), attrs, el)

-- | `tabNavRoot [] [ tabNavLink … ]`
-- | → `<nav class="rt-TabNavRoot"><div class="rt-reset rt-BaseTabList rt-TabNavList"
-- | role="tablist" aria-orientation="horizontal">…</div></nav>`.
-- | Size default 2 on the list (last-wins over caller props). A caller `Color`
-- | lands on the root `<nav>` as `data-accent-color`; all other props ride the list.
tabNavRoot :: forall w i. Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
tabNavRoot props children =
  HH.element (HH.ElemName "nav")
    ( attrs [ "rt-TabNavRoot" ] (filter isColor props)
        <> [ HP.attr (HH.AttrName "aria-label") "Main"
           , HP.attr (HH.AttrName "data-orientation") "horizontal"
           , HP.attr (HH.AttrName "dir") "ltr"
           ]
    )
    -- NavigationMenuList wraps the <ul> in the indicatorTrack <div style="position: relative">
    -- (NOT display:contents, so the normalizer keeps it).
    [ HH.div [ HP.style "position: relative;" ]
        [ el "ul" [ "rt-reset", "rt-BaseTabList", "rt-TabNavList" ]
            ( [ Size "2"
              , DataAttr "orientation" "horizontal"
              , RawAttr "dir" "ltr"
              ] <> filter (not <<< isColor) props
            )
            children
        ]
    ]
  where
  -- The accent color is the only axis the root <nav> carries; everything else
  -- styles the inner list.
  isColor = case _ of
    Color _ -> true
    _ -> false

-- | `tabNavLink active "#account" [] [ HH.text "Account" ]`
-- | → `<div class="rt-TabNavItem"><a class="rt-reset rt-BaseTabListTrigger
-- | rt-TabNavLink" href="#account" data-active?>…</a></div>`. `active` emits the
-- | bare `data-active` boolean attribute Radix NavigationMenu sets on the current
-- | link (absent when inactive).
tabNavLink :: forall w i. Boolean -> String -> Array Prop -> Array (HH.HTML w i) -> HH.HTML w i
tabNavLink active href props children =
  HH.element (HH.ElemName "li")
    [ HP.class_ (HH.ClassName "rt-TabNavItem") ]
    [ HH.element (HH.ElemName "a")
        ( attrs [ "rt-reset", "rt-BaseTabListTrigger", "rt-TabNavLink" ]
            ( [ RawAttr "href" href
              -- Radix's Collection.ItemSlot (FocusGroupItem) stamps this marker attr.
              , DataAttr "radix-collection-item" ""
              ]
                <> (if active then [ DataAttr "active" "", RawAttr "aria-current" "page" ] else [])
                <> props
            )
        )
        [ HH.span
            [ HP.class_ (HH.ClassName "rt-BaseTabListTriggerInner rt-TabNavLinkInner") ]
            children
        , HH.span
            [ HP.class_ (HH.ClassName "rt-BaseTabListTriggerInnerHidden rt-TabNavLinkInnerHidden") ]
            children
        ]
    ]
