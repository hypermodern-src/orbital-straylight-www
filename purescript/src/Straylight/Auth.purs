-- | Auth/data wiring for straylight-web — the Supabase client, on the canonical
-- | buck2 paved path. @supabase/supabase-js is inherited transitively from
-- | `hydrogen//integrations/supabase:lib` (PursLibInfo) and bundled into
-- | straylight.js; this module never declares an npm dependency itself. Proves
-- | the real SDK stack end-to-end in the flagship (STR-239).
module Straylight.Auth
  ( initSupabase
  ) where

import Prelude

import Effect (Effect)
import Effect.Console (log)
import Data.Maybe (Maybe(..))
import Hydrogen.Integration.Supabase (Client, createClient, getSession)

-- | Construct the Supabase client and report current session state. Wired into
-- | the app entry so the SDK is live in the bundle (replace the placeholders with
-- | the project URL + anon key, or thread them from the host page at runtime).
initSupabase :: Effect Client
initSupabase = do
  client <- createClient "https://YOUR-PROJECT.supabase.co" "YOUR-ANON-KEY"
  getSession client case _ of
    Just _ -> log "straylight: supabase session active"
    Nothing -> log "straylight: supabase anonymous"
  pure client
