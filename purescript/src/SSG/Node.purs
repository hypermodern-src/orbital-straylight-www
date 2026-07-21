-- | The minimal node surface the generator needs. Kept as local FFI so the
-- | package stays free of node-* dependencies (the browser bundle never sees
-- | this module).
module SSG.Node
  ( argv
  , mkdirp
  , writeTextFile
  ) where

import Prelude

import Effect (Effect)

foreign import argv :: Effect (Array String)

foreign import mkdirp :: String -> Effect Unit

foreign import writeTextFile :: String -> String -> Effect Unit
