-- | Clerk integration (STR-240) — a typed surface over @clerk/clerk-js, bundled
-- | hermetically via straylight-prelude's npm placement-tree model (562 placements,
-- | depth-5 nesting, peers external). Implements hydrogen's `AuthProvider` frame
-- | hook, so an app gates routes with the generic `Hydrogen.Frame.guardRoute` and
-- | never names Clerk in its routing logic.
module Hydrogen.Integration.Clerk
  ( Clerk
  , load
  , isSignedIn
  , openSignIn
  ) where

import Prelude

import Effect (Effect)
import Hydrogen.Frame (class AuthProvider, AuthStatus(..))

-- | A loaded Clerk instance (`new Clerk(publishableKey)` + `await clerk.load()`).
foreign import data Clerk :: Type

foreign import loadImpl :: String -> (Clerk -> Effect Unit) -> Effect Unit

-- | Construct Clerk from the publishable key and await `load()`, then hand back
-- | the ready instance.
load :: String -> (Clerk -> Effect Unit) -> Effect Unit
load = loadImpl

-- | Whether a user is currently signed in (`!!clerk.user`).
foreign import isSignedIn :: Clerk -> Effect Boolean

-- | Open Clerk's hosted sign-in modal/redirect (a Clerk-specific capability
-- | beyond the AuthProvider frame interface).
foreign import openSignIn :: Clerk -> Effect Unit

foreign import clerkSignOut :: Clerk -> Effect Unit

foreign import addListenerImpl
  :: Clerk -> (Boolean -> Effect Unit) -> Effect (Effect Unit)

-- | Clerk is an `AuthProvider`: subscribe maps Clerk's listener to AuthStatus;
-- | signOut delegates to the SDK.
instance authProviderClerk :: AuthProvider Clerk where
  subscribeAuth clerk cb =
    addListenerImpl clerk \signed -> cb (if signed then SignedIn else Anonymous)
  signOut = clerkSignOut
