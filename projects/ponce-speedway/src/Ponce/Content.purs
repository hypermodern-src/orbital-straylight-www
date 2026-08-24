module Ponce.Content
  ( SiteData
  , Site
  , Page
  , Hero
  , Section
  , Spec
  , TimelineEntry
  , Faq
  , Contact
  , Cta
  , Card
  , Localized
  , NavItem
  , Footer
  , PoweredBy
  , Stat
  , Turn
  , decodeSiteData
  ) where

import Data.Argonaut.Core (Json)
import Data.Argonaut.Decode (decodeJson, printJsonDecodeError)
import Data.Either (Either(..))
import Data.Maybe (Maybe)

type Localized a =
  { en :: a
  , es :: a
  }

type Site =
  { name :: String
  , tagline :: Localized String
  , description :: Localized String
  }

type NavItem =
  { slug :: Localized String
  , label :: Localized String
  }

type PoweredBy =
  { name :: String
  , line :: String
  }

type Footer =
  { blurb :: Localized String
  , poweredBy :: Array PoweredBy
  }

type Stat =
  { value :: String
  , label :: Localized String
  }

type Turn =
  { name :: String
  , desc :: Localized String
  }

type Hero =
  { image :: String
  , gl :: Boolean
  , kicker :: Localized String
  }

type Spec =
  { k :: Localized String
  , v :: Localized String
  }

type TimelineEntry =
  { when :: Localized String
  , what :: Localized String
  }

type Faq =
  { q :: Localized String
  , a :: Localized String
  }

type Contact =
  { email :: String
  , phone :: String
  }

type Cta =
  { label :: Localized String
  , slug :: Localized String
  }

type Card =
  { title :: Localized String
  , text :: Localized String
  , slug :: Maybe (Localized String)
  }

type Section =
  { heading :: Maybe (Localized String)
  , body :: Maybe (Localized String)
  , quote :: Maybe (Localized String)
  , list :: Maybe (Localized (Array String))
  , specs :: Maybe (Array Spec)
  , timeline :: Maybe (Array TimelineEntry)
  , faq :: Maybe (Array Faq)
  , map :: Boolean
  , turns :: Boolean
  , contact :: Maybe Contact
  , cta :: Maybe Cta
  , signup :: Boolean
  , cards :: Maybe (Array Card)
  , image :: Maybe String
  }

type Page =
  { slug :: Localized String
  , title :: Localized String
  , hero :: Hero
  , heroHeadline :: Localized String
  , heroSub :: Localized String
  , sections :: Array Section
  }

type SiteData =
  { site :: Site
  , nav :: Array NavItem
  , footer :: Footer
  , stats :: Array Stat
  , turns :: Array Turn
  , pages :: Array Page
  }

decodeSiteData :: Json -> Either String SiteData
decodeSiteData json = case decodeJson json of
  Left error -> Left (printJsonDecodeError error)
  Right siteData -> Right siteData
