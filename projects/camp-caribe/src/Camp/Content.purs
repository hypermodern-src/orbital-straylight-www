module Camp.Content
  ( SiteData
  , Site
  , Localized
  , NavItem
  , Page
  , Fact
  , Hero
  , Intro
  , Statement
  , Capability
  , Home
  , Space
  , Operation
  , Venue
  , Use
  , Missions
  , Video
  , Photo
  , Gallery
  , Fields
  , Contact
  , Footer
  , decodeSiteData
  ) where

import Data.Argonaut.Core (Json)
import Data.Argonaut.Decode (decodeJson, printJsonDecodeError)
import Data.Either (Either(..))

type Localized a =
  { en :: a
  , es :: a
  }

type Site =
  { name :: String
  , canonical :: String
  , phoneDisplay :: String
  , phoneHref :: String
  , email :: String
  , location :: Localized String
  , description :: Localized String
  }

type NavItem =
  { key :: String
  , slug :: Localized String
  , label :: Localized String
  }

type Page =
  { key :: String
  , slug :: Localized String
  , title :: Localized String
  , description :: Localized String
  }

type Fact =
  { value :: String
  , label :: Localized String
  }

type Hero =
  { eyebrow :: Localized String
  , title :: Localized String
  , deck :: Localized String
  , primary :: Localized String
  , secondary :: Localized String
  }

type Intro =
  { eyebrow :: Localized String
  , title :: Localized String
  , body :: Localized String
  }

type Statement =
  { eyebrow :: Localized String
  , title :: Localized String
  , body :: Localized String
  }

type Capability =
  { index :: String
  , title :: Localized String
  , body :: Localized String
  , image :: String
  , alt :: Localized String
  }

type Home =
  { hero :: Hero
  , intro :: Intro
  , statement :: Statement
  , capabilitiesEyebrow :: Localized String
  , capabilitiesTitle :: Localized String
  , capabilities :: Array Capability
  , locationEyebrow :: Localized String
  , locationTitle :: Localized String
  , locationBody :: Localized String
  }

type Space = Capability

type Operation =
  { title :: Localized String
  , body :: Localized String
  }

type Venue =
  { eyebrow :: Localized String
  , title :: Localized String
  , deck :: Localized String
  , introTitle :: Localized String
  , introBody :: Localized (Array String)
  , spacesEyebrow :: Localized String
  , spacesTitle :: Localized String
  , spaces :: Array Space
  , operationsEyebrow :: Localized String
  , operationsTitle :: Localized String
  , operations :: Array Operation
  }

type Use = Capability

type Missions =
  { eyebrow :: Localized String
  , title :: Localized String
  , deck :: Localized String
  , introTitle :: Localized String
  , introBody :: Localized String
  , uses :: Array Use
  , closingTitle :: Localized String
  , closingBody :: Localized String
  }

type Video =
  { title :: Localized String
  , source :: String
  , poster :: String
  }

type Photo =
  { image :: String
  , label :: Localized String
  }

type Gallery =
  { eyebrow :: Localized String
  , title :: Localized String
  , deck :: Localized String
  , videoEyebrow :: Localized String
  , videoTitle :: Localized String
  , videos :: Array Video
  , photoEyebrow :: Localized String
  , photoTitle :: Localized String
  , photos :: Array Photo
  }

type Fields =
  { name :: Localized String
  , organization :: Localized String
  , email :: Localized String
  , phone :: Localized String
  , groupSize :: Localized String
  , dates :: Localized String
  , purpose :: Localized String
  , message :: Localized String
  , submit :: Localized String
  }

type Contact =
  { eyebrow :: Localized String
  , title :: Localized String
  , deck :: Localized String
  , directTitle :: Localized String
  , directBody :: Localized String
  , formTitle :: Localized String
  , formBody :: Localized String
  , fields :: Fields
  , purposeOptions :: Localized (Array String)
  , arrivalTitle :: Localized String
  , arrivalBody :: Localized String
  }

type Footer =
  { tagline :: Localized String
  , summary :: Localized String
  , rights :: Localized String
  }

type SiteData =
  { site :: Site
  , nav :: Array NavItem
  , pages :: Array Page
  , facts :: Array Fact
  , home :: Home
  , venue :: Venue
  , missions :: Missions
  , gallery :: Gallery
  , contact :: Contact
  , footer :: Footer
  }

decodeSiteData :: Json -> Either String SiteData
decodeSiteData json = case decodeJson json of
  Left error -> Left (printJsonDecodeError error)
  Right siteData -> Right siteData
