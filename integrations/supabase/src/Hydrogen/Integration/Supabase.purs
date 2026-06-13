-- | Supabase integration (STR-239) — a typed PureScript surface over
-- | @supabase/supabase-js, packaged as a first-class hydrogen library cell. The
-- | SDK's 9-package npm closure rides up to any consuming app via PursLibInfo:
-- | an app adds `deps = ["hydrogen//integrations/supabase:lib"]` and the SDK
-- | lands on esbuild's NODE_PATH automatically — no npm_packages of its own.
-- |
-- | Async methods are continuation-passing (error + success callbacks; the JS
-- | does `.then(onOk).catch(onErr)`) so this library's closure is `effect`-only.
-- | Apps wrap them in Aff/Promise at their boundary.
module Hydrogen.Integration.Supabase
  ( Client
  , Session
  , Credentials
  , createClient
  , signInWithPassword
  , signOut
  , getSession
  , onAuthStateChange
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)

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

-- | `auth.signOut()`.
foreign import signOut :: Client -> (String -> Effect Unit) -> Effect Unit -> Effect Unit

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
