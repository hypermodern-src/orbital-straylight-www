-- | Auth/data wiring for straylight-web, on hydrogen's plugin frame. The app
-- | programs against `Hydrogen.Frame` (FrameworkContext + AuthProvider/Session),
-- | not against Supabase directly — swapping to Clerk is a one-line change in the
-- | BUCK (`integrations = ["clerk"]`) plus the createClient call. The SDK is
-- | inherited transitively from `hydrogen//integrations/supabase:lib` (STR-239).
module Straylight.Auth
  ( initAuth
  , protect
  ) where

import Prelude

import Effect (Effect)
import Hydrogen.Frame (Session, mkSession, AuthStatus(..), RouterContext(..), guardRoute)
import Hydrogen.Integration.Supabase (createClient)

-- | Bring up the Supabase-backed framework session. Supabase is an
-- | `AuthProvider`, so `mkSession` builds the provider-agnostic `Session` the
-- | rest of the app depends on (live URL/anon-key are placeholders).
initAuth :: Effect Session
initAuth = do
  client <- createClient "https://YOUR-PROJECT.supabase.co" "YOUR-ANON-KEY"
  mkSession Anonymous client

-- | The `Router.isProtected` wiring for this app: gate a route on the session +
-- | redirect via the app's RouterContext. Provider-agnostic — `guardRoute` never
-- | names Supabase or Clerk.
protect :: Session -> Boolean -> Effect Boolean
protect = guardRoute RouterContext
