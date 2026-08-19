-- | A dependency-free source viewer. Syntax remains source text; path, line
-- | count, sticky gutter, selection state, and overflow are structural.
module Hydrogen.Orbital.Code
  ( CodeViewerInput
  , defaultCodeViewer
  , codeViewer
  ) where

import Prelude

import DOM.HTML.Indexed (HTMLdiv, HTMLspan)
import Data.Array (elem, length, mapWithIndex)
import Data.String.Common (split)
import Data.String.Pattern (Pattern(..))
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Orbital.Foundation (classNames)

type CodeViewerInput i =
  { path :: String
  , language :: String
  , code :: String
  , startLine :: Int
  , selectedLines :: Array Int
  , lineAttrs :: Int -> Array (HH.IProp HTMLspan i)
  , class_ :: String
  , attrs :: Array (HH.IProp HTMLdiv i)
  }

defaultCodeViewer :: forall i. CodeViewerInput i
defaultCodeViewer =
  { path: "untitled"
  , language: "text"
  , code: ""
  , startLine: 1
  , selectedLines: []
  , lineAttrs: const []
  , class_: ""
  , attrs: []
  }

codeViewer :: forall w i. CodeViewerInput i -> HH.HTML w i
codeViewer o =
  HH.div
    ( [ HP.class_ (HH.ClassName (classNames [ "codeview", "orbital-code-viewer", o.class_ ]))
      , HP.attr (HH.AttrName "data-language") o.language
      ] <> o.attrs
    )
    [ HH.div [ HP.class_ (HH.ClassName "cv-head") ]
        [ HH.span [ HP.class_ (HH.ClassName "cv-path") ] [ HH.text o.path ]
        , HH.span [ HP.class_ (HH.ClassName "cv-meta") ]
            [ HH.text (o.language <> " · " <> show (length sourceLines) <> " lines") ]
        ]
    , HH.div
        [ HP.class_ (HH.ClassName "cv-scroll")
        , HP.tabIndex 0
        , HP.attr (HH.AttrName "role") "region"
        , HP.attr (HH.AttrName "aria-label") ("Source code: " <> o.path)
        ]
        [ HH.div [ HP.class_ (HH.ClassName "orbital-code-lines") ]
            (mapWithIndex renderLine sourceLines)
        ]
    ]
  where
  sourceLines = split (Pattern "\n") o.code
  renderLine index source =
    let
      lineNumber = o.startLine + index
      state = if elem lineNumber o.selectedLines then "selected" else "inactive"
    in
      HH.span
        ( [ HP.class_ (HH.ClassName "orbital-code-line")
          , HP.attr (HH.AttrName "data-state") state
          , HP.attr (HH.AttrName "data-line") (show lineNumber)
          ] <> o.lineAttrs lineNumber
        )
        [ HH.span [ HP.class_ (HH.ClassName "orbital-code-line-number"), HP.attr (HH.AttrName "aria-hidden") "true" ] [ HH.text (show lineNumber) ]
        , HH.code [ HP.class_ (HH.ClassName "orbital-code-source") ] [ HH.text (if source == "" then " " else source) ]
        ]
