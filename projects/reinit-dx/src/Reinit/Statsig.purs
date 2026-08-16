-- | Statsig FFI for experiment variants
module Reinit.Statsig
  ( HeroVariant
  , getHeroVariant
  , logCtaClick
  , logSubmit
  ) where

import Prelude

import Effect (Effect)

-- | Hero copy variant from Statsig experiment
type HeroVariant =
  { variant :: String
  , headline :: String
  , subhead :: String
  , tagline :: String
  , cta :: String
  }

-- | Get current hero variant (sync - uses cached values)
foreign import getHeroVariant :: Effect HeroVariant

-- | Log CTA click event
foreign import logCtaClick :: String -> Effect Unit

-- | Log form submit event
foreign import logSubmit :: String -> Effect Unit
