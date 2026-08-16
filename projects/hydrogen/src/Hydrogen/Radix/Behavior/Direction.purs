-- | Hydrogen.Radix.Behavior.Direction — reading direction (radix `Direction`).
-- |
-- | radix threads `ltr`/`rtl` through React context; in Halogen we thread it
-- | explicitly as a value in component input (default `LTR`). It flips the
-- | meaning of horizontal arrow keys in roving-focus groups, tabs, sliders, etc.
module Hydrogen.Radix.Behavior.Direction
  ( Dir(..)
  , dirName
  , fromString
  ) where

import Prelude

import Data.Maybe (Maybe(..))

data Dir = LTR | RTL

derive instance eqDir :: Eq Dir
derive instance ordDir :: Ord Dir

instance showDir :: Show Dir where
  show = dirName

dirName :: Dir -> String
dirName = case _ of
  LTR -> "ltr"
  RTL -> "rtl"

fromString :: String -> Maybe Dir
fromString = case _ of
  "ltr" -> Just LTR
  "rtl" -> Just RTL
  _ -> Nothing
