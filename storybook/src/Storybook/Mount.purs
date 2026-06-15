-- | Storybook.Mount — the single FFI seam between Storybook and the Halogen
-- | `Hydrogen.Themes` components.
-- |
-- | `purs_browser_bundle` emits a self-running bundle, so `main` attaches a
-- | `mount(componentId, args, element)` function to `window.hydrogenStorybook`.
-- | Each Storybook story calls it with its component id + the live control `args`;
-- | `render` maps those args to the component's `Array Prop` and Halogen renders
-- | it into the story's canvas element. The `.radix-themes` Theme wrapper + the
-- | Radix stylesheet are supplied by the Storybook preview decorator, so a story
-- | renders identically to the pixel goldens.
module Storybook.Mount (main) where

import Prelude

import Data.Function.Uncurried (Fn3, mkFn3)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.VDom.Driver (runUI)
import Hydrogen.Themes.Badge (badge)
import Hydrogen.Themes.Button (button)
import Hydrogen.Themes.Prop (Prop(..))
import Hydrogen.Themes.Switch (switch)
import Web.DOM (Element)
import Web.HTML.HTMLElement (fromElement)

-- | An opaque handle to the JS Storybook `args` object (control values).
foreign import data Args :: Type

-- | Read a string/boolean control, with a default when absent.
foreign import argStr :: String -> String -> Args -> String
foreign import argBool :: String -> Boolean -> Args -> Boolean

-- | Install `window.hydrogenStorybook = { mount }`.
foreign import attach :: Fn3 String Args Element (Effect Unit) -> Effect Unit

main :: Effect Unit
main = attach (mkFn3 mount)

mount :: String -> Args -> Element -> Effect Unit
mount cid args el = case fromElement el of
  Nothing -> pure unit
  Just he -> HA.runHalogenAff (void (runUI (static (render cid args)) unit he))
  where
  static html =
    H.mkComponent
      { initialState: const unit
      , render: const html
      , eval: H.mkEval H.defaultEval
      }

-- | Map a component id + control args to the rendered component.
render :: forall w i. String -> Args -> HH.HTML w i
render cid args = case cid of
  "button" ->
    button (enum "variant" Variant <> enum "size" Size <> enum "color" Color)
      [ HH.text (argStr "label" "Button" args) ]
  "badge" ->
    badge (enum "variant" Variant <> enum "color" Color)
      [ HH.text (argStr "label" "Badge" args) ]
  "switch" ->
    switch (argBool "checked" true args) (argBool "disabled" false args) []
  _ -> HH.text ("unknown component: " <> cid)
  where
  -- an enum control → its Prop, dropped when the control is empty/unset
  enum key ctor = let v = argStr key "" args in if v == "" then [] else [ ctor v ]
