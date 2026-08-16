{- |
Module      : Straylight.Web.Middleware.Config
Description : Validated environment configuration for the reference runner.

The reusable middleware itself does not read process configuration. This
module belongs to the tiny runner and accumulates every boot fault so a bad
deployment can be corrected in one pass.
-}
module Straylight.Web.Middleware.Config (
    ConfigError (..),
    ServerConfig (..),
    assembleServerConfig,
    loadServerConfig,
) where

import Data.Text (Text)
import Data.Text qualified as Text
import System.Environment (lookupEnv)
import Text.Read (readMaybe)

data ServerConfig = ServerConfig
    { serverHost :: String
    , serverPort :: Int
    , serverShutdownSeconds :: Int
    , serverMaxJsonBodyBytes :: Int
    }
    deriving stock (Eq, Show)

newtype ConfigError = ConfigError Text
    deriving stock (Eq, Show)

-- | Read all supported environment variables before validating any of them.
loadServerConfig :: IO (Either [ConfigError] ServerConfig)
loadServerConfig = do
    host <- lookupEnv "STRAYLIGHT_MIDDLEWARE_HOST"
    port <- lookupEnv "STRAYLIGHT_MIDDLEWARE_PORT"
    shutdown <- lookupEnv "STRAYLIGHT_MIDDLEWARE_SHUTDOWN_SECONDS"
    maxBody <- lookupEnv "STRAYLIGHT_MIDDLEWARE_MAX_JSON_BODY_BYTES"
    pure (assembleServerConfig host port shutdown maxBody)

-- | Pure configuration assembly for deterministic tests.
assembleServerConfig ::
    Maybe String ->
    Maybe String ->
    Maybe String ->
    Maybe String ->
    Either [ConfigError] ServerConfig
assembleServerConfig hostRaw portRaw shutdownRaw maxBodyRaw =
    case (hostResult, portResult, shutdownResult, maxBodyResult) of
        (Right host, Right port, Right shutdown, Right maxBody) ->
            Right
                ServerConfig
                    { serverHost = host
                    , serverPort = port
                    , serverShutdownSeconds = shutdown
                    , serverMaxJsonBodyBytes = maxBody
                    }
        _ -> Left (faults [hostResult, showResult portResult, showResult shutdownResult, showResult maxBodyResult])
  where
    hostResult = case hostRaw of
        Nothing -> Right "0.0.0.0"
        Just "" -> Left (ConfigError "STRAYLIGHT_MIDDLEWARE_HOST must not be empty")
        Just host -> Right host
    portResult = boundedInt "STRAYLIGHT_MIDDLEWARE_PORT" 8080 1 65535 portRaw
    shutdownResult = boundedInt "STRAYLIGHT_MIDDLEWARE_SHUTDOWN_SECONDS" 10 1 300 shutdownRaw
    maxBodyResult = boundedInt "STRAYLIGHT_MIDDLEWARE_MAX_JSON_BODY_BYTES" (1024 * 1024) 1 (64 * 1024 * 1024) maxBodyRaw
    showResult = fmap show

faults :: [Either ConfigError String] -> [ConfigError]
faults = foldr collect []
  where
    collect (Left fault) rest = fault : rest
    collect (Right _) rest = rest

boundedInt :: Text -> Int -> Int -> Int -> Maybe String -> Either ConfigError Int
boundedInt _name fallback _minimum _maximum Nothing = Right fallback
boundedInt name _fallback lowerBound upperBound (Just raw)
    | Just value <- readMaybe raw
    , value >= lowerBound
    , value <= upperBound =
        Right value
    | otherwise =
        Left
            ( ConfigError
                ( name
                    <> " must be an integer between "
                    <> Text.pack (show lowerBound)
                    <> " and "
                    <> Text.pack (show upperBound)
                )
            )
