-- | Clerk integration (STR-240) — a typed PureScript surface over @clerk/clerk-js,
-- | bundled hermetically. Clerk's closure is the case a flat node_modules can't
-- | hold (562 placements, nesting depth 5, peers external); straylight-prelude's
-- | npm placement-tree model images bun's solve and esbuild bundles it through the
-- | real nested tree. Apps add `deps = ["hydrogen//integrations/clerk:lib"]` and
-- | inherit the whole closure transitively via PursLibInfo.
-- |
-- | `guardRoute` is the Hydrogen.Router wiring: combine a route's `isProtected`
-- | (the `RouteMetadata` typeclass) with Clerk's signed-in state to gate
-- | navigation — call it from the app's navigation handler with
-- | `isProtected route` for the target.
module Hydrogen.Integration.Clerk
  ( Clerk
  , load
  , isSignedIn
  , openSignIn
  , signOut
  , addListener
  , guardRoute
  ) where

import Prelude

import Effect (Effect)

-- | A loaded Clerk instance (`new Clerk(publishableKey)` + `await clerk.load()`).
foreign import data Clerk :: Type

foreign import loadImpl :: String -> (Clerk -> Effect Unit) -> Effect Unit

-- | Construct Clerk from the publishable key and await `load()`, then hand back
-- | the ready instance.
load :: String -> (Clerk -> Effect Unit) -> Effect Unit
load = loadImpl

-- | Whether a user is currently signed in (`!!clerk.user`).
foreign import isSignedIn :: Clerk -> Effect Boolean

-- | Open Clerk's hosted sign-in modal/redirect.
foreign import openSignIn :: Clerk -> Effect Unit

-- | Sign the current user out.
foreign import signOut :: Clerk -> Effect Unit

-- | Subscribe to auth-state changes; the callback receives the new signed-in
-- | state. Returns the unsubscribe effect.
foreign import addListener :: Clerk -> (Boolean -> Effect Unit) -> Effect (Effect Unit)

-- | Router integration (`Router.isProtected` wiring): if the target route is
-- | protected and no user is signed in, open sign-in and report `false`
-- | (withhold navigation); otherwise report `true` (allow).
guardRoute :: Clerk -> Boolean -> Effect Boolean
guardRoute clerk protected =
  if protected then do
    signed <- isSignedIn clerk
    if signed then pure true
    else do
      openSignIn clerk
      pure false
  else pure true
