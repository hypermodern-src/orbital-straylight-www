-- | Straylight UI Components for Halogen
-- | Extends Hydrogen.UI with the straylight aesthetic
module Straylight.UI 
  ( -- * Re-exports from Hydrogen.UI.Core
    module Hydrogen.UI.Core
    -- * Straylight-specific typography
  , sectionHeader
  , heading
  , text
  , quote
  , keyword
    -- * Straylight-specific decorative elements
  , rail
  , statusIndicator
  , scanlineOverlay
    -- * Straylight-specific links
  , navLink
  , externalLink
  , footerLink
    -- * Code blocks
  , codeBlock
  , inlineCode
  , blockCursor
  ) where

import Prelude

import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Hydrogen.UI.Core (classes, cls, svgCls, flex, row, column, box, container, section, svgNS)

-- ============================================================
-- TYPOGRAPHY
-- ============================================================

-- | Section header with code formatting
sectionHeader :: forall w i. String -> HH.HTML w i
sectionHeader title =
  HH.h2
    [ cls [ "text-primary text-[0.85rem] font-medium mb-6 lowercase section-header" ] ]
    [ HH.code_ [ HH.text $ "// " <> title ] ]

-- | Primary heading
heading :: forall w i. String -> Array (HH.HTML w i) -> HH.HTML w i
heading className = HH.h1 [ cls [ "text-text text-[2rem] font-medium", className ] ]

-- | Body text
text :: forall w i. String -> Array (HH.HTML w i) -> HH.HTML w i
text className = HH.p [ cls [ "text-muted-foreground", className ] ]

-- | Italic quote text
quote :: forall w i. String -> Array (HH.HTML w i) -> HH.HTML w i
quote className = HH.p [ cls [ "italic text-base02", className ] ]

-- | Keyword span with glow animation
keyword :: forall w i. Int -> String -> HH.HTML w i
keyword n content =
  HH.span
    [ cls [ "text-text keyword keyword-" <> show n ] ]
    [ HH.text content ]

-- ============================================================
-- DECORATIVE ELEMENTS
-- ============================================================

-- | Horizontal rail with shimmer effect
rail :: forall w i. HH.HTML w i
rail = HH.div [ cls [ "h-[3px] rail" ] ] []

-- | Status indicator
statusIndicator :: forall w i. String -> HH.HTML w i
statusIndicator label =
  HH.div
    [ cls [ "flex items-center gap-2 text-xs text-muted-foreground" ] ]
    [ HH.span [ cls [ "w-2 h-2 bg-status inline-block status-pulse" ] ] []
    , HH.text label
    ]

-- | Scanline overlay
scanlineOverlay :: forall w i. HH.HTML w i
scanlineOverlay = HH.div [ cls [ "scanline-overlay" ] ] []

-- ============================================================
-- LINKS
-- ============================================================

-- | Navigation link with trace animation
navLink :: forall w i. String -> String -> HH.HTML w i
navLink href label =
  HH.a
    [ HP.href href
    , cls [ "text-muted-foreground text-[13px] hover:text-text transition-colors link-trace" ]
    ]
    [ HH.text label ]

-- | External link
externalLink :: forall w i. String -> String -> HH.HTML w i
externalLink href label =
  HH.a
    [ HP.href href
    , HP.target "_blank"
    , HP.rel "noopener noreferrer"
    , cls [ "text-muted-foreground text-[13px] hover:text-text transition-colors link-trace" ]
    ]
    [ HH.text label ]

-- | Footer link with float animation
footerLink :: forall w i. String -> String -> HH.HTML w i
footerLink href label =
  HH.a
    [ HP.href href
    , HP.target "_blank"
    , HP.rel "noopener noreferrer"
    , cls [ "text-muted-foreground hover:text-text transition-colors ml-6 link-float inline-block" ]
    ]
    [ HH.text label ]

-- ============================================================
-- CODE BLOCKS
-- ============================================================

-- | Terminal-style code block
codeBlock :: forall w i. Array (HH.HTML w i) -> HH.HTML w i
codeBlock children =
  HH.pre
    [ cls [ "bg-card p-4 overflow-x-auto text-[0.9rem] leading-relaxed" ] ]
    children

-- | Inline code
inlineCode :: forall w i. String -> HH.HTML w i
inlineCode content =
  HH.code
    [ cls [ "text-muted-foreground" ] ]
    [ HH.text content ]

-- | Block cursor (blinking)
blockCursor :: forall w i. HH.HTML w i
blockCursor = HH.span [ cls [ "block-cursor" ] ] []
