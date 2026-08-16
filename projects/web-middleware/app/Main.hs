module Main (
    main,
) where

import Control.Exception (IOException, catch)
import Data.Aeson (ToJSON, encode, object, (.=))
import Data.ByteString qualified as ByteString
import Data.ByteString.Lazy qualified as LBS
import Data.String (fromString)
import Data.Text (Text)
import Network.HTTP.Types (hContentType, methodGet, status200, status404)
import Network.Wai (Application, pathInfo, requestMethod, responseLBS)
import Network.Wai.Handler.Warp qualified as Warp
import Straylight.Web.Middleware qualified as Web
import Straylight.Web.Middleware.Config (
    ConfigError (ConfigError),
    ServerConfig (..),
    loadServerConfig,
 )
import System.Exit (exitFailure)
import System.IO (stderr)
import System.Posix.Signals (Handler (Catch), installHandler, sigINT, sigTERM)

main :: IO ()
main = loadServerConfig >>= either reportFaults startServer

reportFaults :: [ConfigError] -> IO ()
reportFaults faults = do
    mapM_ report faults
    exitFailure
  where
    report (ConfigError message) =
        writeJsonLine $
            object ["kind" .= ("config_error" :: Text), "message" .= message]

startServer :: ServerConfig -> IO ()
startServer config = do
    let policy =
            Web.defaultMiddlewareSettings
                { Web.middlewareMaxJsonBodyBytes = serverMaxJsonBodyBytes config
                }
    runtime <- Web.newRuntime policy
    Warp.runSettings (settings runtime config) (Web.middleware runtime application)
        `catch` bindFault config

settings :: Web.Runtime -> ServerConfig -> Warp.Settings
settings runtime config =
    Warp.setPort (serverPort config)
        . Warp.setHost (fromString (serverHost config))
        . Warp.setServerName "straylight"
        . Warp.setGracefulShutdownTimeout (Just (serverShutdownSeconds config))
        . Warp.setInstallShutdownHandler (installSignalHandlers runtime)
        . Warp.setBeforeMainLoop (Web.markReady runtime >> reportListening config)
        $ Warp.defaultSettings

installSignalHandlers :: Web.Runtime -> IO () -> IO ()
installSignalHandlers runtime closeSocket = do
    let drainAndClose = Web.beginDrain runtime >> closeSocket
    _ <- installHandler sigTERM (Catch drainAndClose) Nothing
    _ <- installHandler sigINT (Catch drainAndClose) Nothing
    pure ()

reportListening :: ServerConfig -> IO ()
reportListening config =
    writeJsonLine $
        object
            [ "kind" .= ("server_listening" :: Text)
            , "host" .= serverHost config
            , "port" .= serverPort config
            ]

bindFault :: ServerConfig -> IOException -> IO ()
bindFault config exception = do
    writeJsonLine $
        object
            [ "kind" .= ("bind_error" :: Text)
            , "host" .= serverHost config
            , "port" .= serverPort config
            , "error" .= show exception
            ]
    exitFailure

writeJsonLine :: (ToJSON value) => value -> IO ()
writeJsonLine value = ByteString.hPut stderr (LBS.toStrict (encode value) <> "\n")

application :: Application
application request respond
    | requestMethod request == methodGet && pathInfo request == [] =
        respond
            ( responseLBS
                status200
                [(hContentType, "application/json")]
                (encode (object ["service" .= ("straylight-web-middleware" :: Text), "status" .= ("ok" :: Text)]))
            )
    | otherwise = respond (Web.jsonErrorResponse status404 "not_found" "resource not found")
