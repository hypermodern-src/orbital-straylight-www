-- | Deck state and actions — the whole app is one state machine.
module Site.Types
  ( State
  , Action(..)
  , initialState
  , darkPanels
  , panelCount
  , sectionNames
  ) where

import Data.Array (elem)
import Web.UIEvent.KeyboardEvent (KeyboardEvent)
import Web.UIEvent.MouseEvent (MouseEvent)

type State =
  { page :: Int
  , overlayOpen :: Boolean
  , dark :: Boolean -- onosendai theme
  , locked :: Boolean -- transition lock (900ms)
  }

data Action
  = Initialize
  | Go Int
  | Scrub MouseEvent
  | OpenOverlay
  | CloseOverlay
  | ToggleTheme
  | KeyDown KeyboardEvent
  | Paged Int -- +1 / -1 from wheel or swipe
  | Unlock

initialState :: State
initialState = { page: 0, overlayOpen: false, dark: false, locked: false }

-- | Panels 4 (Method) and 5 (Principles) run dark chrome.
darkPanels :: Int -> Boolean
darkPanels i = i `elem` [ 4, 5 ]

panelCount :: Int
panelCount = 7

sectionNames :: Array String
sectionNames = [ "Home", "Thesis", "Practices", "Record", "Method", "Principles", "Inquiries" ]
