-- | Pins the typed names that connect Hydrogen.Orbital to the canonical CSS.
module Test.Orbital (suite) where

import Prelude

import Effect (Effect)
import Hydrogen.Orbital.Foundation
  ( Appearance(..)
  , ColorToken(..)
  , ComponentSize(..)
  , FontToken(..)
  , RadiusToken(..)
  , SpaceToken(..)
  , Surface(..)
  , Tone(..)
  , appearanceName
  , breakpointLap
  , classNames
  , colorVar
  , fontVar
  , radiusVar
  , sizeClass
  , spaceVar
  , surfaceName
  , toneClass
  )
import Hydrogen.Test.Assert (assertEqual, section)

suite :: Effect Unit
suite = do
  section "Orbital — root axes" do
    assertEqual "light appearance" "light" (appearanceName Light)
    assertEqual "Ono-sendai attribute value" "onosendai" (appearanceName OnoSendai)
    assertEqual "page surface" "page" (surfaceName Page)
    assertEqual "true-black surface" "black" (surfaceName Black)
    assertEqual "single adaptivity breakpoint" 900 breakpointLap

  section "Orbital — component axes" do
    assertEqual "neutral adds no modifier" "" (toneClass Neutral)
    assertEqual "accent modifier" "is-accent" (toneClass Accent)
    assertEqual "warning modifier uses house spelling" "is-warn" (toneClass Warning)
    assertEqual "error modifier" "is-error" (toneClass Error)
    assertEqual "medium is the unmodified size" "" (sizeClass Medium)
    assertEqual "small modifier" "is-sm" (sizeClass Small)
    assertEqual "large modifier" "is-lg" (sizeClass Large)
    assertEqual "empty modifiers are removed" "btn primary custom" (classNames [ "btn", "", "primary", "custom" ])

  section "Orbital — semantic tokens" do
    assertEqual "body text" "var(--text-body)" (colorVar TextBody)
    assertEqual "glass surface" "var(--surface-glass)" (colorVar SurfaceGlass)
    assertEqual "success signal" "var(--signal-success)" (colorVar SignalSuccess)
    assertEqual "display remains mono" "var(--font-display)" (fontVar Display)
    assertEqual "prose is the serif exception" "var(--font-prose)" (fontVar Prose)
    assertEqual "section rhythm" "var(--space-section)" (spaceVar SpaceSection)
    assertEqual "panel radius" "var(--radius-md)" (radiusVar PanelRadius)
