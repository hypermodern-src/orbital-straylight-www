-- | ORBITAL's design vocabulary, encoded as closed PureScript types.
-- |
-- | These values name the canonical custom properties shipped in
-- | `assets/orbital/styles.css`; they do not duplicate the CSS values. Keeping
-- | components on semantic tokens lets Ono-sendai remain a root token swap.
module Hydrogen.Orbital.Foundation
  ( Appearance(..)
  , appearanceName
  , Surface(..)
  , surfaceName
  , Tone(..)
  , toneClass
  , ComponentSize(..)
  , sizeClass
  , ColorToken(..)
  , colorVar
  , FontToken(..)
  , fontVar
  , SpaceToken(..)
  , spaceVar
  , RadiusToken(..)
  , radiusVar
  , breakpointLap
  , classNames
  ) where

import Prelude

import Data.Array (filter)
import Data.String (joinWith)

-- | Light has no root attribute in the canonical stylesheet. Ono-sendai is
-- | selected by `data-theme="onosendai"` on `<html>`.
data Appearance = Light | OnoSendai

derive instance eqAppearance :: Eq Appearance

appearanceName :: Appearance -> String
appearanceName Light = "light"
appearanceName OnoSendai = "onosendai"

-- | The ordinary page surface, or the optional true-black layer used on top of
-- | Ono-sendai by consumer/mobile shells.
data Surface = Page | Black

derive instance eqSurface :: Eq Surface

surfaceName :: Surface -> String
surfaceName Page = "page"
surfaceName Black = "black"

-- | Neutral plus the four signal colours allowed by the guide.
data Tone = Neutral | Accent | Success | Warning | Error

derive instance eqTone :: Eq Tone

toneClass :: Tone -> String
toneClass Neutral = ""
toneClass Accent = "is-accent"
toneClass Success = "is-success"
toneClass Warning = "is-warn"
toneClass Error = "is-error"

data ComponentSize = Small | Medium | Large

derive instance eqComponentSize :: Eq ComponentSize

sizeClass :: ComponentSize -> String
sizeClass Small = "is-sm"
sizeClass Medium = ""
sizeClass Large = "is-lg"

-- | Semantic colour roles from `tokens/aliases.css`.
data ColorToken
  = TextBody
  | TextStrong
  | TextMuted
  | TextFaint
  | TextAccent
  | SurfacePage
  | SurfaceRaised
  | SurfaceGlass
  | SurfaceGlassHover
  | SurfaceCarbon
  | SurfaceCode
  | Line
  | LineFaint
  | LineGlass
  | LineAccent
  | Interactive
  | InteractiveHover
  | FocusRing
  | Selection
  | SignalAccent
  | SignalSuccess
  | SignalWarning
  | SignalError

colorVar :: ColorToken -> String
colorVar TextBody = "var(--text-body)"
colorVar TextStrong = "var(--text-strong)"
colorVar TextMuted = "var(--text-muted)"
colorVar TextFaint = "var(--text-faint)"
colorVar TextAccent = "var(--text-accent)"
colorVar SurfacePage = "var(--surface-page)"
colorVar SurfaceRaised = "var(--surface-raised)"
colorVar SurfaceGlass = "var(--surface-glass)"
colorVar SurfaceGlassHover = "var(--surface-glass-hover)"
colorVar SurfaceCarbon = "var(--surface-carbon)"
colorVar SurfaceCode = "var(--surface-code)"
colorVar Line = "var(--line)"
colorVar LineFaint = "var(--line-faint)"
colorVar LineGlass = "var(--line-glass)"
colorVar LineAccent = "var(--line-accent)"
colorVar Interactive = "var(--interactive)"
colorVar InteractiveHover = "var(--interactive-hover)"
colorVar FocusRing = "var(--focus-ring)"
colorVar Selection = "var(--selection)"
colorVar SignalAccent = "var(--signal-accent)"
colorVar SignalSuccess = "var(--signal-success)"
colorVar SignalWarning = "var(--signal-warn)"
colorVar SignalError = "var(--signal-error)"

-- | Mono is both the display and UI voice. Prose is the deliberate serif
-- | exception for essays, papers, pull quotes, and axioms.
data FontToken = Display | UI | Prose

fontVar :: FontToken -> String
fontVar Display = "var(--font-display)"
fontVar UI = "var(--font-ui)"
fontVar Prose = "var(--font-prose)"

data SpaceToken
  = Space1
  | Space2
  | Space3
  | Space4
  | Space5
  | Space6
  | Space7
  | SpaceSection
  | Gutter

spaceVar :: SpaceToken -> String
spaceVar Space1 = "var(--space-1)"
spaceVar Space2 = "var(--space-2)"
spaceVar Space3 = "var(--space-3)"
spaceVar Space4 = "var(--space-4)"
spaceVar Space5 = "var(--space-5)"
spaceVar Space6 = "var(--space-6)"
spaceVar Space7 = "var(--space-7)"
spaceVar SpaceSection = "var(--space-section)"
spaceVar Gutter = "var(--gutter)"

data RadiusToken = ControlRadius | PanelRadius

radiusVar :: RadiusToken -> String
radiusVar ControlRadius = "var(--radius-sm)"
radiusVar PanelRadius = "var(--radius-md)"

-- | The single adaptivity breakpoint in the guide, in CSS pixels.
breakpointLap :: Int
breakpointLap = 900

-- | Join class tokens while dropping empty variants such as Neutral/Medium.
classNames :: Array String -> String
classNames = joinWith " " <<< filter (_ /= "")
