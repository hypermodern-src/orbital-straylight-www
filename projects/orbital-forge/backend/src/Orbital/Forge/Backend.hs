module Orbital.Forge.Backend
  ( Backend (..)
  ) where

import Data.ByteString (ByteString)
import Network.Wai (Application)

-- | A provider adapter behind the stable Orbital Forge HTTP contract.
-- The first implementation delegates reads to Forgejo; a native store can
-- replace it without changing the browser application.
data Backend = Backend
  { backendName :: ByteString
  , backendApplication :: Application
  }
