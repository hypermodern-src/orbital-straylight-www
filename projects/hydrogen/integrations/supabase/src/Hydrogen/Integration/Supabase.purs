-- | Supabase integration (STR-239) — a typed surface over @supabase/supabase-js,
-- | bundled via the transitive paved path (the SDK's flat 9-pkg closure rides up
-- | through PursLibInfo). Implements hydrogen's `AuthProvider` frame hook, so it's
-- | interchangeable with Clerk behind `Hydrogen.Frame` (the app's routing logic
-- | names neither).
-- |
-- | Async methods are continuation-passing (`.then(onOk).catch(onErr)`), so this
-- | library's closure stays `effect`-only; apps wrap in Aff at their boundary.
module Hydrogen.Integration.Supabase
  ( Client
  , Session
  , Credentials
  , createClient
  , signInWithPassword
  , getSession
  , onAuthStateChange
  ) where

import Prelude

import Data.Maybe (Maybe(..), maybe)
import Effect (Effect)
import Hydrogen.Frame (class AuthProvider, AuthStatus(..))

-- | An opaque @supabase/supabase-js client (the result of `createClient`).
foreign import data Client :: Type

-- | An opaque auth session (access token + user). Kept opaque so the binding
-- | does not pin a shape the SDK may evolve; read fields via further FFI.
foreign import data Session :: Type

type Credentials = { email :: String, password :: String }

-- | `createClient(supabaseUrl, supabaseAnonKey)`.
foreign import createClient :: String -> String -> Effect Client

foreign import signInWithPasswordImpl
  :: Client
  -> Credentials
  -> (String -> Effect Unit)
  -> (Session -> Effect Unit)
  -> Effect Unit

-- | `auth.signInWithPassword({ email, password })`. Calls `onError` with the
-- | error message or `onSuccess` with the session.
signInWithPassword
  :: Client
  -> Credentials
  -> (String -> Effect Unit)
  -> (Session -> Effect Unit)
  -> Effect Unit
signInWithPassword = signInWithPasswordImpl

foreign import signOutImpl :: Client -> (String -> Effect Unit) -> Effect Unit -> Effect Unit

foreign import getSessionImpl
  :: Client
  -> (Session -> Maybe Session)
  -> Maybe Session
  -> (Maybe Session -> Effect Unit)
  -> Effect Unit

-- | `auth.getSession()`. Calls back with `Just session` when signed in, else
-- | `Nothing`.
getSession :: Client -> (Maybe Session -> Effect Unit) -> Effect Unit
getSession client k = getSessionImpl client Just Nothing k

foreign import onAuthStateChangeImpl
  :: Client
  -> (Session -> Maybe Session)
  -> Maybe Session
  -> (Maybe Session -> Effect Unit)
  -> Effect (Effect Unit)

-- | `auth.onAuthStateChange(cb)` — fires with the current session (or `Nothing`
-- | on sign-out) whenever auth state changes. Returns the unsubscribe effect.
onAuthStateChange :: Client -> (Maybe Session -> Effect Unit) -> Effect (Effect Unit)
onAuthStateChange client k = onAuthStateChangeImpl client Just Nothing k

-- | Supabase is an `AuthProvider`: subscribe maps the session stream to
-- | AuthStatus; signOut delegates to the SDK (errors swallowed at the frame
-- | level — surface them through the typed API if you need them).
instance authProviderClient :: AuthProvider Client where
  subscribeAuth client cb =
    onAuthStateChange client \ms -> cb (maybe Anonymous (const SignedIn) ms)
  signOut client = signOutImpl client (\_ -> pure unit) (pure unit)
