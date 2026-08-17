module Orbital.Pages.Publications
  ( journalContent
  , papersContent
  , publicationContent
  ) where

import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

journalContent :: forall w i. HH.HTML w i
journalContent =
  indexContent
    "Journal"
    "Notes from the machinery."
    "Engineering dispatches, product decisions, and field notes from the people building Orbital."
    "post"

papersContent :: forall w i. HH.HTML w i
papersContent =
  indexContent
    "Research"
    "Papers with receipts."
    "Technical papers, specifications, and results behind Orbital's verified infrastructure."
    "paper"

publicationContent :: forall w i. HH.HTML w i
publicationContent =
  HH.element (HH.ElemName "main")
    [ HP.attr (HH.AttrName "class") "wrap narrow publication-page" ]
    [ HH.element (HH.ElemName "div")
        [ HP.id "publications-app"
        , HP.attr (HH.AttrName "data-publications-mode") "reader"
        , HP.attr (HH.AttrName "aria-live") "polite"
        ]
        [ loadingState "Loading publication" ]
    ]

indexContent :: forall w i. String -> String -> String -> String -> HH.HTML w i
indexContent eyebrow title lede kind =
  HH.element (HH.ElemName "main")
    [ HP.attr (HH.AttrName "class") "wrap narrow publication-page" ]
    [ HH.element (HH.ElemName "header")
        [ HP.attr (HH.AttrName "class") "publication-hero" ]
        [ HH.element (HH.ElemName "div")
            [ HP.attr (HH.AttrName "class") "eyebrow"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.text eyebrow ]
        , HH.element (HH.ElemName "h1")
            [ HP.attr (HH.AttrName "data-reveal") "" ]
            [ HH.text title ]
        , HH.element (HH.ElemName "p")
            [ HP.attr (HH.AttrName "class") "lede"
            , HP.attr (HH.AttrName "data-reveal") ""
            ]
            [ HH.text lede ]
        ]
    , HH.element (HH.ElemName "div")
        [ HP.id "publications-app"
        , HP.attr (HH.AttrName "data-publications-mode") kind
        , HP.attr (HH.AttrName "aria-live") "polite"
        ]
        [ loadingState "Loading publications" ]
    ]

loadingState :: forall w i. String -> HH.HTML w i
loadingState label =
  HH.element (HH.ElemName "div")
    [ HP.attr (HH.AttrName "class") "publication-status" ]
    [ HH.element (HH.ElemName "span")
        [ HP.attr (HH.AttrName "class") "spinner"
        , HP.attr (HH.AttrName "aria-hidden") "true"
        ]
        []
    , HH.element (HH.ElemName "span") [] [ HH.text label ]
    ]
