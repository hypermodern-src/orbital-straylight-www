{- |
Module      : Straylight.Web.Middleware.Runtime
Description : Process-local middleware state and injectable effects.

The runtime owns no product or business state. Its only mutable cell is the
operational readiness gate used during boot and graceful drain.
-}
module Straylight.Web.Middleware.Runtime (
    MiddlewareSettings (..),
    Readiness (..),
    RequestObservation (..),
    Runtime,
    beginDrain,
    defaultMiddlewareSettings,
    defaultSecurityHeaders,
    markReady,
    markWarming,
    newRuntime,
    readReadiness,
    runtimeReadinessCell,
    runtimeRequestIdKey,
    runtimeSettings,
    stderrExceptionReporter,
    stderrJsonObserver,
) where

import Control.Concurrent.STM (TVar, atomically, modifyTVar', newTVarIO, readTVarIO, writeTVar)
import Control.Exception (SomeException)
import Data.Aeson (ToJSON (toJSON), encode, object, (.=))
import Data.ByteString qualified as ByteString
import Data.ByteString.Lazy qualified as LBS
import Data.Text (Text)
import Data.Text.Encoding (decodeUtf8With)
import Data.Text.Encoding.Error (lenientDecode)
import Data.Vault.Lazy qualified as Vault
import Network.HTTP.Types (ResponseHeaders)
import Network.Wai (Request, rawPathInfo)
import System.IO (stderr)

-- | The only process lifecycle states visible at the readiness endpoint.
data Readiness
    = Warming
    | Ready
    | Draining
    deriving stock (Eq, Show)

{- | One privacy-bounded request measurement. Query strings and headers are
deliberately absent so credentials cannot leak into the default log sink.
-}
data RequestObservation = RequestObservation
    { observationRequestId :: Text
    , observationMethod :: Text
    , observationPath :: Text
    , observationStatus :: Int
    , observationDurationMilliseconds :: Int
    }
    deriving stock (Eq, Show)

instance ToJSON RequestObservation where
    toJSON RequestObservation{..} =
        object
            [ "kind" .= ("http_request" :: Text)
            , "request_id" .= observationRequestId
            , "method" .= observationMethod
            , "path" .= observationPath
            , "status" .= observationStatus
            , "duration_ms" .= observationDurationMilliseconds
            ]

-- | Application-supplied policy and effect hooks.
data MiddlewareSettings = MiddlewareSettings
    { middlewareMaxJsonBodyBytes :: Int
    , middlewareSecurityHeaders :: ResponseHeaders
    , middlewareObserveRequest :: RequestObservation -> IO ()
    , middlewareReportException :: Request -> SomeException -> IO ()
    }

-- | Process-local state allocated once before the server binds.
data Runtime = Runtime
    { runtimeSettings :: MiddlewareSettings
    , runtimeRequestIdKey :: Vault.Key Text
    , runtimeReadinessCell :: TVar Readiness
    }

{- | Headers safe to apply to both APIs and server-rendered documents. CSP and
HSTS are intentionally app/deployment policy and therefore not guessed here.
-}
defaultSecurityHeaders :: ResponseHeaders
defaultSecurityHeaders =
    [ ("X-Content-Type-Options", "nosniff")
    , ("Referrer-Policy", "no-referrer")
    , ("X-Frame-Options", "DENY")
    , ("Cross-Origin-Opener-Policy", "same-origin")
    , ("Cross-Origin-Resource-Policy", "same-origin")
    , ("Permissions-Policy", "camera=(), microphone=(), geolocation=()")
    ]

{- | Conservative defaults: 1 MiB JSON bodies, hardened responses, structured
stderr request observations, and internal exception reporting.
-}
defaultMiddlewareSettings :: MiddlewareSettings
defaultMiddlewareSettings =
    MiddlewareSettings
        { middlewareMaxJsonBodyBytes = 1024 * 1024
        , middlewareSecurityHeaders = defaultSecurityHeaders
        , middlewareObserveRequest = stderrJsonObserver
        , middlewareReportException = stderrExceptionReporter
        }

{- | Allocate a cold runtime. Call 'markReady' only when dependencies and the
listening socket are ready to receive traffic.
-}
newRuntime :: MiddlewareSettings -> IO Runtime
newRuntime runtimeSettings =
    Runtime runtimeSettings <$> Vault.newKey <*> newTVarIO Warming

markReady :: Runtime -> IO ()
markReady runtime = atomically (modifyTVar' (runtimeReadinessCell runtime) transition)
  where
    transition Draining = Draining
    transition _ = Ready

markWarming :: Runtime -> IO ()
markWarming runtime = atomically (modifyTVar' (runtimeReadinessCell runtime) transition)
  where
    transition Draining = Draining
    transition _ = Warming

-- | Flip readiness before closing the listening socket.
beginDrain :: Runtime -> IO ()
beginDrain runtime = atomically (writeTVar (runtimeReadinessCell runtime) Draining)

readReadiness :: Runtime -> IO Readiness
readReadiness = readTVarIO . runtimeReadinessCell

-- | Default one-JSON-object-per-line request sink.
stderrJsonObserver :: RequestObservation -> IO ()
stderrJsonObserver = writeJsonLine . toJSON

-- | Default internal exception sink. The error never crosses the HTTP wire.
stderrExceptionReporter :: Request -> SomeException -> IO ()
stderrExceptionReporter request exception =
    writeJsonLine $
        object
            [ "kind" .= ("server_exception" :: Text)
            , "path" .= decodeUtf8With lenientDecode (rawPathInfo request)
            , "error" .= show exception
            ]

writeJsonLine :: (ToJSON value) => value -> IO ()
writeJsonLine value = ByteString.hPut stderr (LBS.toStrict (encode value) <> "\n")
