module Main (
    main,
) where

import Control.Exception (SomeException, bracket, try)
import Data.Aeson (ToJSON, encode, object, (.=))
import Data.ByteString qualified as ByteString
import Data.ByteString.Lazy qualified as LBS
import Data.Maybe (isJust)
import Data.String (fromString)
import Data.Text (Text)
import Network.Wai.Handler.Warp qualified as Warp
import System.Exit (exitFailure)
import System.IO (stderr)
import System.Posix.Signals (Handler (Catch), installHandler, sigINT, sigTERM)

import Straylight.Cms.Application (AppEnv (..), application)
import Straylight.Cms.Config (Config (..), ConfigError (..), loadConfig)
import Straylight.Cms.Store (StoreError (..))
import Straylight.Cms.Store.Postgres (
    PostgresStore,
    closePostgresStore,
    newPostgresStore,
    pingPostgresStore,
    postgresStore,
 )
import Straylight.Web.Middleware qualified as Web

main :: IO ()
main = do
    loaded <- loadConfig
    case loaded of
        Left faults -> reportConfigFaults faults >> exitFailure
        Right config -> do
            result <- tryAny (runService config)
            case result of
                Left _ -> do
                    writeJsonLine $ object ["kind" .= ("startup_error" :: Text), "message" .= ("publishing service could not start" :: Text)]
                    exitFailure
                Right () -> pure ()

runService :: Config -> IO ()
runService config =
    bracket
        (newPostgresStore (configDatabaseUrl config) (configDatabasePoolSize config))
        closePostgresStore
        (serve config)

serve :: Config -> PostgresStore -> IO ()
serve config database = do
    pingPostgresStore database >>= \case
        Left (StoreUnavailable message) -> failText message
        Left _ -> failText "publishing store failed its startup check"
        Right () -> pure ()
    runtime <- Web.newRuntime Web.defaultMiddlewareSettings
    let environment =
            AppEnv
                { appStore = postgresStore database
                , appEditorToken = configEditorToken config
                , appEditorActor = configEditorActor config
                }
    Warp.runSettings
        (settings runtime config)
        (Web.middleware runtime (application environment))

settings :: Web.Runtime -> Config -> Warp.Settings
settings runtime config =
    Warp.setPort (configPort config)
        . Warp.setHost (fromString (configHost config))
        . Warp.setServerName "straylight"
        . Warp.setGracefulShutdownTimeout (Just (configShutdownSeconds config))
        . Warp.setInstallShutdownHandler (installSignalHandlers runtime)
        . Warp.setBeforeMainLoop (Web.markReady runtime >> reportListening config)
        $ Warp.defaultSettings

installSignalHandlers :: Web.Runtime -> IO () -> IO ()
installSignalHandlers runtime closeSocket = do
    let drainAndClose = Web.beginDrain runtime >> closeSocket
    _ <- installHandler sigTERM (Catch drainAndClose) Nothing
    _ <- installHandler sigINT (Catch drainAndClose) Nothing
    pure ()

reportListening :: Config -> IO ()
reportListening config =
    writeJsonLine $
        object
            [ "kind" .= ("server_listening" :: Text)
            , "host" .= configHost config
            , "port" .= configPort config
            , "editorial_enabled" .= isJust (configEditorToken config)
            ]

reportConfigFaults :: [ConfigError] -> IO ()
reportConfigFaults = mapM_ $ \(ConfigError message) ->
    writeJsonLine $ object ["kind" .= ("config_error" :: Text), "message" .= message]

failText :: Text -> IO value
failText _ = ioError (userError "publishing store is unavailable")

tryAny :: IO value -> IO (Either SomeException value)
tryAny = try

writeJsonLine :: (ToJSON value) => value -> IO ()
writeJsonLine value = ByteString.hPut stderr (LBS.toStrict (encode value) <> "\n")
