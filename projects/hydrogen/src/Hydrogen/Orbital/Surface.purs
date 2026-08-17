-- | ORBITAL's first composed surfaces: glass, ruled sections, records, figures,
-- | and the theme-independent carbon terminal.
module Hydrogen.Orbital.Surface
  ( GlassCardInput
  , defaultGlassCard
  , GlassCardContent
  , glassCard
  , SectionHeadInput
  , defaultSectionHead
  , sectionHead
  , Stat
  , statBand
  , MetaRow
  , metaList
  , TerminalLine(..)
  , TerminalInput
  , defaultTerminal
  , terminal
  ) where

import Prelude

import DOM.HTML.Indexed (HTMLdiv)
import Data.Array (null)
import Data.Maybe (Maybe(..))
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Orbital.Foundation (classNames)

type GlassCardInput r i =
  { href :: Maybe String
  , lift :: Boolean
  , class_ :: String
  , attrs :: Array (HH.IProp (class :: String, style :: String | r) i)
  }

defaultGlassCard :: forall r i. GlassCardInput r i
defaultGlassCard = { href: Nothing, lift: true, class_: "", attrs: [] }

type GlassCardContent w i =
  { kicker :: Array (HH.HTML w i)
  , title :: Array (HH.HTML w i)
  , body :: Array (HH.HTML w i)
  , footer :: Array (HH.HTML w i)
  }

glassCard :: forall r w i. GlassCardInput r i -> GlassCardContent w i -> HH.HTML w i
glassCard o content =
  HH.element (HH.ElemName tag)
    ( [ HP.class_ (HH.ClassName classes)
      , HP.style "border-radius: var(--radius-lg); display: flex; flex-direction: column; gap: .5rem;"
      ] <> hrefAttr <> o.attrs
    )
    (kicker <> title <> body <> footer)
  where
  tag = case o.href of
    Nothing -> "div"
    Just _ -> "a"
  hrefAttr = case o.href of
    Nothing -> []
    Just href -> [ HP.attr (HH.AttrName "href") href ]
  classes = classNames
    [ "glass"
    , if o.lift then "orbital-lift orbital-sweep" else ""
    , o.class_
    ]
  kicker = if null content.kicker then [] else
    [ HH.div
        [ HP.class_ (HH.ClassName "fk")
        , HP.style "font-family: var(--sans); font-size: 1.15rem; font-weight: 500; letter-spacing: -.02em; color: var(--ink-m); line-height: 1;"
        ]
        content.kicker
    ]
  title = if null content.title then [] else
    [ HH.h3
        [ HP.style "font-family: var(--sans); font-weight: 500; font-size: .95rem; letter-spacing: -.02em; color: var(--ink);" ]
        content.title
    ]
  body = if null content.body then [] else [ HH.p_ content.body ]
  footer = if null content.footer then [] else
    [ HH.div [ HP.style "margin-top: auto; padding-top: .7rem;" ] content.footer ]

type SectionHeadInput w i =
  { number :: Maybe String
  , note :: Array (HH.HTML w i)
  , class_ :: String
  , attrs :: Array (HH.IProp HTMLdiv i)
  }

defaultSectionHead :: forall w i. SectionHeadInput w i
defaultSectionHead = { number: Nothing, note: [], class_: "", attrs: [] }

sectionHead :: forall w i. SectionHeadInput w i -> Array (HH.HTML w i) -> HH.HTML w i
sectionHead o title =
  HH.div
    ( [ HP.class_ (HH.ClassName (classNames [ "sh", o.class_ ])) ] <> o.attrs )
    (number <> [ HH.h2_ title ] <> note)
  where
  number = case o.number of
    Nothing -> []
    Just value -> [ HH.span [ HP.class_ (HH.ClassName "n") ] [ HH.text value ] ]
  note = if null o.note then [] else
    [ HH.span
        [ HP.style "margin-left: auto; font-size: .72rem; color: var(--ink-m); max-width: 34ch; text-align: right; line-height: 1.6;" ]
        o.note
    ]

type Stat w i = { value :: Array (HH.HTML w i), label :: String }

statBand :: forall w i. Array (HH.IProp HTMLdiv i) -> Array (Stat w i) -> HH.HTML w i
statBand attrs stats =
  HH.div ([ HP.class_ (HH.ClassName "statband") ] <> attrs) (map render stats)
  where
  render stat =
    HH.div [ HP.class_ (HH.ClassName "st") ]
      [ HH.span [ HP.class_ (HH.ClassName "v") ] stat.value
      , HH.span [ HP.class_ (HH.ClassName "k") ] [ HH.text stat.label ]
      ]

type MetaRow w i = { key :: String, value :: Array (HH.HTML w i) }

metaList :: forall w i. Array (HH.IProp HTMLdiv i) -> Array (MetaRow w i) -> HH.HTML w i
metaList attrs rows =
  HH.div ([ HP.class_ (HH.ClassName "metalist") ] <> attrs) (map render rows)
  where
  render row =
    HH.div [ HP.class_ (HH.ClassName "metarow") ]
      [ HH.span [ HP.class_ (HH.ClassName "my") ] [ HH.text row.key ]
      , HH.span [ HP.class_ (HH.ClassName "mt") ] row.value
      ]

data TerminalLine
  = Prompt String
  | Output String
  | Comment String
  | Okay String
  | Emphasis String

type TerminalInput i =
  { title :: String
  , cursor :: Boolean
  , class_ :: String
  , attrs :: Array (HH.IProp HTMLdiv i)
  }

defaultTerminal :: forall i. TerminalInput i
defaultTerminal = { title: "shell", cursor: true, class_: "", attrs: [] }

terminal :: forall w i. TerminalInput i -> Array TerminalLine -> HH.HTML w i
terminal o lines =
  HH.div
    ( [ HP.class_ (HH.ClassName (classNames [ "term", o.class_ ])) ] <> o.attrs )
    [ HH.div [ HP.class_ (HH.ClassName "term-bar") ]
        [ HH.i_ [], HH.i_ [], HH.i_ []
        , HH.span [ HP.class_ (HH.ClassName "tt") ] [ HH.text o.title ]
        ]
    , HH.pre_ (map renderLine lines <> cursor)
    ]
  where
  cursor = if o.cursor then [ HH.span [ HP.class_ (HH.ClassName "cur") ] [] ] else []
  renderLine line = HH.div_ [ HH.span [ HP.class_ (HH.ClassName (lineClass line)) ] [ HH.text (lineText line) ] ]

lineClass :: TerminalLine -> String
lineClass (Prompt _) = "pr"
lineClass (Output _) = ""
lineClass (Comment _) = "cm"
lineClass (Okay _) = "ok"
lineClass (Emphasis _) = "ac"

lineText :: TerminalLine -> String
lineText (Prompt value) = "$ " <> value
lineText (Output value) = value
lineText (Comment value) = value
lineText (Okay value) = value
lineText (Emphasis value) = value
