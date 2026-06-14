-- | The gallery's story contract. A story is a SELF-CONTAINED Halogen component
-- | (it owns whatever internal slots its reproduction needs), so every story lives
-- | in its own `Gallery.Story.<Name>` module and the gallery never grows a shared
-- | slot row. The gallery mounts the selected story through ONE uniform slot keyed
-- | by story id — adding a story is a new module + one line in `Gallery.Main`.
module Gallery.Story
  ( Story
  , StoryComponent
  , GallerySlots
  , _story
  , staticStory
  ) where

import Prelude

import Data.Const (Const)
import Data.Void (Void)
import Effect.Aff (Aff)
import Halogen as H
import Type.Proxy (Proxy(..))

-- | A story component: no query, unit input, no output. Whatever stateful radix
-- | primitives it embeds are its own private slots — invisible here.
type StoryComponent = H.Component (Const Void) Unit Void Aff

type Story = { id :: String, component :: StoryComponent }

-- | The gallery's single slot: every story mounts here, distinguished by its id.
type GallerySlots = (story :: H.Slot (Const Void) Void String)

_story :: Proxy "story"
_story = Proxy

-- | Build a story from a static (no internal slots) bit of HTML — the common case
-- | for the unstyled/uncontrolled reproductions.
staticStory :: String -> H.ComponentHTML Void () Aff -> Story
staticStory id view =
  { id
  , component: H.mkComponent
      { initialState: const unit
      , render: const view
      , eval: H.mkEval H.defaultEval
      }
  }
