module Orbital.SSG.Node
  ( mkdirp
  , outputDirectory
  , writeTextFile
  ) where

import Prelude (Unit)

import Effect (Effect)

foreign import mkdirp :: String -> Effect Unit

foreign import outputDirectory :: Effect String

foreign import writeTextFile :: String -> String -> Effect Unit
