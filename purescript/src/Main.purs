-- | Client entry. The static document already contains the exact deck DOM;
-- | we clear the shell and mount the live state machine in its place.
module Main where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Class (liftEffect)
import Halogen.Aff as HA
import Halogen.VDom.Driver (runUI)
import Site.Deck as Deck
import Web.DOM.Element as Element
import Web.DOM.Node (setTextContent)
import Web.DOM.ParentNode (QuerySelector(..), querySelector)
import Web.HTML (window)
import Web.HTML.HTMLDocument as HTMLDocument
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.Window (document)

main :: Effect Unit
main = launchAff_ do
  HA.awaitLoad
  doc <- liftEffect $ window >>= document
  let parent = HTMLDocument.toParentNode doc
  mbContainer <- liftEffect $ querySelector (QuerySelector "#app") parent
  case mbContainer >>= HTMLElement.fromElement of
    Nothing -> pure unit
    Just container -> do
      liftEffect $ setTextContent "" (Element.toNode (HTMLElement.toElement container))
      void $ runUI Deck.component unit container
