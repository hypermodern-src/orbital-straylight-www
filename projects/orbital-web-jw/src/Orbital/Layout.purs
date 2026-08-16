module Orbital.Layout (page) where

import Prelude

import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Orbital.Route (Route(..), fileName)

page :: forall w i. Route -> HH.HTML w i -> HH.HTML w i
page route content =
  HH.div_
    [ navigation route
    , content
    , footer route
    ]

navigation :: forall w i. Route -> HH.HTML w i
navigation route =
  HH.nav
    [ HP.attr (HH.AttrName "class") "bar" ]
    [ HH.span
        [ HP.attr (HH.AttrName "class") "brand" ]
        [ HH.span
            [ HP.attr (HH.AttrName "class") "mk" ]
            [ HH.element (HH.ElemName "svg")
                [ HP.attr (HH.AttrName "viewBox") "0 0 96 66"
                , HP.attr (HH.AttrName "fill") "currentColor"
                , HP.attr (HH.AttrName "aria-hidden") "true"
                ]
                [ HH.element (HH.ElemName "path")
                    [ HP.attr (HH.AttrName "d") "m 18,18 v 20 l -17.32,10 10,17.32 h 40 l 10,-17.32 17.32,10 17.32,-10 -10,-17.32 h -20 v -20 L 48,.68 l -10,17.32 z" ]
                    []
                ]
            ]
        , HH.span [ HP.attr (HH.AttrName "class") "t" ] [ HH.text "Orbital" ]
        ]
    , HH.div
        [ HP.attr (HH.AttrName "class") "topnav" ]
        [ navLink route Overview "Overview"
        , navLink route Cache "Cache"
        , navLink route Build "Build"
        , navLink route Pricing "Pricing"
        , navLink route Verification "Verification"
        , navLink route About "About"
        ]
    ]

navLink :: forall w i. Route -> Route -> String -> HH.HTML w i
navLink current target label =
  HH.a
    ( [ HP.href (fileName target) ]
        <> if current == target then [ HP.attr (HH.AttrName "class") "here" ] else []
    )
    [ HH.text label ]

footer :: forall w i. Route -> HH.HTML w i
footer route =
  HH.div
    [ HP.attr (HH.AttrName "class") "wrap" ]
    [ HH.div
        [ HP.attr (HH.AttrName "class") "foot" ]
        [ HH.span_
            [ HH.text
                ( if route == About then "ORBITAL © 2026 · San Juan, PR"
                  else "ORBITAL © 2026"
                )
            ]
        , HH.span_
            ( footerLink "about.html" "About"
                <> separator
                <> externalLink "https://github.com/sensenet-ai" "GitHub"
                <> separator
                <> footerLink "#" "Changelog"
                <> separator
                <> footerLink "#" "Status"
                <> licenses route
                <> separator
                <> footerLink "pricing.html" "Pricing"
            )
        ]
    ]

footerLink :: forall w i. String -> String -> Array (HH.HTML w i)
footerLink href label = [ HH.a [ HP.href href ] [ HH.text label ] ]

externalLink :: forall w i. String -> String -> Array (HH.HTML w i)
externalLink href label =
  [ HH.a
      [ HP.href href
      , HP.target "_blank"
      , HP.rel "noopener"
      ]
      [ HH.text label ]
  ]

separator :: forall w i. Array (HH.HTML w i)
separator = [ HH.text " · " ]

licenses :: forall w i. Route -> Array (HH.HTML w i)
licenses About = []
licenses _ = separator <> footerLink "#" "Licenses"
