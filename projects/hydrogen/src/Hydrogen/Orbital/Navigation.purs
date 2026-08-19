-- | ORBITAL navigation primitives: federated chrome, breadcrumbs, and tabs.
module Hydrogen.Orbital.Navigation
  ( NavItem
  , NavBarInput
  , defaultNavBar
  , navBar
  , BreadcrumbItem
  , breadcrumbs
  , TabItem
  , tabs
  ) where

import Prelude

import DOM.HTML.Indexed (HTMLbutton, HTMLnav)
import Data.Array (length, mapWithIndex, null)
import Data.Maybe (Maybe(..))
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Orbital.Foundation (classNames)

type NavItem =
  { label :: String
  , href :: String
  , current :: Boolean
  }

type NavBarInput w i =
  { brand :: Array (HH.HTML w i)
  , primary :: Array NavItem
  , secondary :: Array NavItem
  , actions :: Array (HH.HTML w i)
  , class_ :: String
  , attrs :: Array (HH.IProp HTMLnav i)
  }

defaultNavBar :: forall w i. NavBarInput w i
defaultNavBar =
  { brand: []
  , primary: []
  , secondary: []
  , actions: []
  , class_: ""
  , attrs: []
  }

navBar :: forall w i. NavBarInput w i -> HH.HTML w i
navBar o =
  HH.nav
    ( [ HP.class_ (HH.ClassName (classNames [ "orbital-nav", o.class_ ]))
      , HP.attr (HH.AttrName "aria-label") "Primary"
      ] <> o.attrs
    )
    [ HH.div [ HP.class_ (HH.ClassName "orbital-nav-brand") ] o.brand
    , HH.div [ HP.class_ (HH.ClassName "orbital-nav-links") ]
        ( map renderItem o.primary
            <> divider
            <> map renderItem o.secondary
            <> o.actions
        )
    ]
  where
  divider =
    if null o.primary || null o.secondary then []
    else [ HH.span [ HP.class_ (HH.ClassName "orbital-nav-divider"), HP.attr (HH.AttrName "aria-hidden") "true" ] [] ]
  renderItem item =
    HH.a
      [ HP.href item.href
      , HP.class_ (HH.ClassName "orbital-nav-link")
      , HP.attr (HH.AttrName "data-state") (if item.current then "active" else "inactive")
      , HP.attr (HH.AttrName "aria-current") (if item.current then "page" else "false")
      ]
      [ HH.text item.label ]

type BreadcrumbItem =
  { label :: String
  , href :: Maybe String
  }

breadcrumbs :: forall w i. Array BreadcrumbItem -> HH.HTML w i
breadcrumbs items =
  HH.nav
    [ HP.class_ (HH.ClassName "orbital-breadcrumbs")
    , HP.attr (HH.AttrName "aria-label") "Breadcrumb"
    ]
    (mapWithIndex render items)
  where
  lastIndex = length items - 1
  render index item =
    HH.span [ HP.class_ (HH.ClassName "orbital-breadcrumb-item") ]
      (node index item <> separator index)
  node index item
    | index == lastIndex =
        [ HH.span
            [ HP.class_ (HH.ClassName "orbital-breadcrumb-current")
            , HP.attr (HH.AttrName "aria-current") "page"
            ]
            [ HH.text item.label ]
        ]
    | otherwise = case item.href of
        Just href -> [ HH.a [ HP.href href ] [ HH.text item.label ] ]
        Nothing -> [ HH.span_ [ HH.text item.label ] ]
  separator index =
    if index == lastIndex then []
    else [ HH.span [ HP.class_ (HH.ClassName "orbital-breadcrumb-separator"), HP.attr (HH.AttrName "aria-hidden") "true" ] [ HH.text "/" ] ]

type TabItem i =
  { label :: String
  , count :: Maybe Int
  , active :: Boolean
  , attrs :: Array (HH.IProp HTMLbutton i)
  }

tabs :: forall w i. String -> Array (TabItem i) -> HH.HTML w i
tabs label items =
  HH.div
    [ HP.class_ (HH.ClassName "orbital-tabs")
    , HP.attr (HH.AttrName "role") "tablist"
    , HP.attr (HH.AttrName "aria-label") label
    ]
    (map render items)
  where
  render item =
    HH.button
      ( [ HP.type_ HP.ButtonButton
        , HP.class_ (HH.ClassName "orbital-tab")
        , HP.attr (HH.AttrName "role") "tab"
        , HP.attr (HH.AttrName "data-state") (if item.active then "active" else "inactive")
        , HP.attr (HH.AttrName "aria-selected") (if item.active then "true" else "false")
        ] <> item.attrs
      )
      ([ HH.text item.label ] <> count item.count)
  count Nothing = []
  count (Just value) = [ HH.span [ HP.class_ (HH.ClassName "orbital-tab-count") ] [ HH.text (show value) ] ]
