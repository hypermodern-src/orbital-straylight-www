-- | Hydrogen.Themes.Floating — the shared Halogen helpers for the anchored overlays
-- | (Popover, Tooltip, HoverCard, DropdownMenu, ContextMenu, Select). The pure
-- | placement math lives in `Hydrogen.Themes.Portal` (`solveAnchored`); this module
-- | is the two pieces that touch Halogen/DOM:
-- |
-- |   * `measureSize` — the ref'd panel's rendered size. The panel is ALWAYS mounted
-- |     (visibility:hidden when closed, NOT display:none), so it has a real size for
-- |     placement even before it shows. Polymorphic in the component's state/action.
-- |   * `panelStyle` — the ONE inline style for an anchored panel: `position: fixed`,
-- |     visibility toggled by `open`, an optional `max-width` kept in BOTH states (so
-- |     the measured size matches the shown size), and the solved top/left.
module Hydrogen.Themes.Floating
  ( measureSize
  , panelStyle
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Web.HTML.HTMLElement as HTMLElement

import Hydrogen.Themes.Portal as Portal

-- | The ref'd element's rendered size (0×0 if the ref isn't mounted).
measureSize :: forall s a sl o m. MonadEffect m => H.RefLabel -> H.HalogenM s a sl o m Portal.Size
measureSize ref =
  H.getHTMLElementRef ref >>= case _ of
    Nothing -> pure { width: 0.0, height: 0.0 }
    Just he -> do
      r <- liftEffect (Portal.anchorRect (HTMLElement.toElement he))
      pure { width: r.width, height: r.height }

-- | The single inline style for an anchored, portaled panel. `maxWidth` "" omits it.
panelStyle :: Boolean -> Number -> Number -> String -> String
panelStyle open top left maxWidth =
  let
    mw = if maxWidth == "" then "" else "max-width: " <> maxWidth <> "; "
  in
    if open then
      "position: fixed; visibility: visible; " <> mw <> "top: " <> show top <> "px; left: " <> show left <> "px"
    else
      "position: fixed; visibility: hidden; " <> mw <> "top: 0; left: 0"
