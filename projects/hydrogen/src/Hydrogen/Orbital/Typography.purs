-- | The guide's type hierarchy as elements, not ad-hoc font choices.
-- |
-- | Titles, headings, numerals, body, and UI are mono. `prose` is the narrow
-- | Cormorant exception for long-form reading; `pullQuote` is the italic serif
-- | exception already defined by the canonical `.pull` contract.
module Hydrogen.Orbital.Typography
  ( display
  , sectionTitle
  , cardTitle
  , eyebrow
  , body
  , prose
  , PullQuoteInput
  , defaultPullQuote
  , pullQuote
  ) where

import Prelude

import DOM.HTML.Indexed (HTMLarticle, HTMLblockquote, HTMLh1, HTMLh2, HTMLh3, HTMLp, HTMLspan)
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.Orbital.Foundation (classNames)

display :: forall w i. Array (HH.IProp HTMLh1 i) -> Array (HH.HTML w i) -> HH.HTML w i
display attrs = HH.h1 ([ HP.class_ (HH.ClassName "orbital-display") ] <> attrs)

sectionTitle :: forall w i. Array (HH.IProp HTMLh2 i) -> Array (HH.HTML w i) -> HH.HTML w i
sectionTitle attrs = HH.h2 ([ HP.class_ (HH.ClassName "orbital-section-title") ] <> attrs)

cardTitle :: forall w i. Array (HH.IProp HTMLh3 i) -> Array (HH.HTML w i) -> HH.HTML w i
cardTitle attrs = HH.h3 ([ HP.class_ (HH.ClassName "orbital-card-title") ] <> attrs)

eyebrow :: forall w i. Array (HH.IProp HTMLspan i) -> Array (HH.HTML w i) -> HH.HTML w i
eyebrow attrs = HH.span ([ HP.class_ (HH.ClassName "orbital-eyebrow") ] <> attrs)

body :: forall w i. Array (HH.IProp HTMLp i) -> Array (HH.HTML w i) -> HH.HTML w i
body attrs = HH.p ([ HP.class_ (HH.ClassName "orbital-body") ] <> attrs)

prose :: forall w i. Array (HH.IProp HTMLarticle i) -> Array (HH.HTML w i) -> HH.HTML w i
prose attrs = HH.article ([ HP.class_ (HH.ClassName "orbital-prose") ] <> attrs)

type PullQuoteInput i =
  { cite :: String
  , class_ :: String
  , attrs :: Array (HH.IProp HTMLblockquote i)
  }

defaultPullQuote :: forall i. PullQuoteInput i
defaultPullQuote = { cite: "", class_: "", attrs: [] }

pullQuote :: forall w i. PullQuoteInput i -> Array (HH.HTML w i) -> HH.HTML w i
pullQuote o children =
  HH.blockquote
    ( [ HP.class_ (HH.ClassName (classNames [ "pull", o.class_ ])) ] <> o.attrs )
    (children <> if o.cite == "" then [] else [ HH.cite_ [ HH.text o.cite ] ])
