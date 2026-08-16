-- | Hydrogen's plugin/integration frame — the hook-point vocabulary.
-- |
-- | Two typeclasses, deliberately distinct (they point in opposite directions):
-- |
-- |   * `FrameworkContext ctx` — what the FRAMEWORK gives an integration: the
-- |     ambient runtime capabilities (navigate, current path, config). The app
-- |     supplies a context value; integrations program against it.
-- |
-- |   * `AuthProvider auth` — what an AUTH integration gives the framework:
-- |     reactive auth state + sign-out. Clerk and Supabase both instance it, so
-- |     the app programs against `AuthProvider` and stays agnostic to which one.
-- |
-- | `guardRoute` is why they're separate: gating a protected route needs auth
-- | state (AuthProvider, via the framework-maintained `Session`) AND navigation
-- | (FrameworkContext). It composes the two.
module Hydrogen.Frame
  ( AuthStatus(..)
  , class AuthProvider
  , subscribeAuth
  , signOut
  , class FrameworkContext
  , navigateTo
  , currentPath
  , lookupConfig
  , Session
  , mkSession
  , sessionStatus
  , sessionSignOut
  , guardRoute
  , RouterContext(..)
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Ref as Ref
import Hydrogen.Runtime.Router (getPathname, pushState)

-- | Reactive auth state. Kept deliberately coarse (no user record) at the frame
-- | level; an integration can expose richer detail through its own module.
data AuthStatus = SignedIn | Anonymous

derive instance eqAuthStatus :: Eq AuthStatus

-- | What an auth integration offers the framework. Reactive: `subscribeAuth` is
-- | the primitive (push), and the framework caches the latest status in a
-- | `Session` so consumers can read it synchronously. Returns the unsubscribe.
class AuthProvider auth where
  subscribeAuth :: auth -> (AuthStatus -> Effect Unit) -> Effect (Effect Unit)
  signOut :: auth -> Effect Unit

-- | What the framework gives an integration: the ambient runtime context. The
-- | app supplies a `ctx` value (e.g. `RouterContext`); integrations call these.
class FrameworkContext ctx where
  navigateTo :: ctx -> String -> Effect Unit
  currentPath :: ctx -> Effect String
  lookupConfig :: ctx -> String -> Effect (Maybe String)

-- | Framework-maintained auth session: the latest `AuthStatus` from any
-- | `AuthProvider`, cached for synchronous reads. This is the decoupling seam —
-- | the rest of the framework depends on `Session`, never on Clerk/Supabase.
newtype Session = Session
  { read :: Effect AuthStatus
  , signOut :: Effect Unit
  }

-- | Build a `Session` from any `AuthProvider`: seed with an initial status, then
-- | subscribe and keep the cached value current.
mkSession :: forall auth. AuthProvider auth => AuthStatus -> auth -> Effect Session
mkSession initial auth = do
  ref <- Ref.new initial
  _ <- subscribeAuth auth \st -> Ref.write st ref
  pure $ Session { read: Ref.read ref, signOut: signOut auth }

sessionStatus :: Session -> Effect AuthStatus
sessionStatus (Session s) = s.read

sessionSignOut :: Session -> Effect Unit
sessionSignOut (Session s) = s.signOut

-- | The `Router.isProtected` wiring, provider-agnostic. If the target route is
-- | protected and the session is anonymous, redirect to sign-in and withhold
-- | navigation (`false`); otherwise allow (`true`). Composes BOTH typeclasses —
-- | `Session` (from an `AuthProvider`) and `FrameworkContext` (to navigate).
guardRoute
  :: forall ctx
   . FrameworkContext ctx
  => ctx
  -> Session
  -> Boolean
  -> Effect Boolean
guardRoute ctx session protected =
  if not protected then pure true
  else sessionStatus session >>= case _ of
    SignedIn -> pure true
    Anonymous -> do
      navigateTo ctx "/sign-in"
      pure false

-- | A concrete `FrameworkContext` backed by Hydrogen.Runtime.Router + a host-provided
-- | global config object (`window.__straylight__`). Apps can use this directly
-- | or supply their own context type.
data RouterContext = RouterContext

instance frameworkContextRouterContext :: FrameworkContext RouterContext where
  navigateTo _ path = pushState path
  currentPath _ = getPathname
  lookupConfig _ key = readConfig key Just Nothing

foreign import readConfig
  :: String
  -> (String -> Maybe String)
  -> Maybe String
  -> Effect (Maybe String)
