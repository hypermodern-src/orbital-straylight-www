module Camp.SSG.Node
  ( contentPath
  , mkdirp
  , outputDirectory
  , readJsonFile
  , writeTextFile
  ) where

import Prelude (Unit)

import Data.Argonaut.Core (Json)
import Effect (Effect)

foreign import contentPath :: Effect String

foreign import mkdirp :: String -> Effect Unit

foreign import outputDirectory :: Effect String

foreign import readJsonFile :: String -> Effect Json

foreign import writeTextFile :: String -> String -> Effect Unit
