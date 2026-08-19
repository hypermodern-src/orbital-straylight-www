{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Data.ByteString (ByteString)
import Data.ByteString.Char8 qualified as BS8
import Data.Maybe (fromMaybe)
import Data.String (fromString)
import Data.Text qualified as Text
import Network.HTTP.Client
  ( ManagerSettings (managerResponseTimeout)
  , responseTimeoutMicro
  )
import Network.HTTP.Client.TLS (newTlsManagerWith, tlsManagerSettings)
import Network.Wai.Handler.Warp
  ( defaultSettings
  , runSettings
  , setHost
  , setPort
  )
import Orbital.Forge.Application (AppConfig (..), mkApplication)
import Orbital.Forge.Backend.Forgejo (ForgejoConfig (..), mkForgejoBackend)
import System.Directory (doesDirectoryExist)
import System.Environment (lookupEnv)
import Text.Read (readMaybe)

main :: IO ()
main = do
  port <- envInt "PORT" 8080
  host <- envString "HOST" "127.0.0.1"
  upstream <- envString "FORGEJO_BASE_URL" "https://git.s4.gl/api/v1"
  organization <- Text.pack <$> envString "FORGEJO_ORGANIZATION" "straylight"
  token <- fmap BS8.pack <$> lookupEnv "FORGEJO_TOKEN"
  origins <- maybe [] parseOrigins <$> lookupEnv "FORGE_CORS_ORIGINS"
  staticDirectory <- discoverPublicDirectory
  manager <- newTlsManagerWith tlsManagerSettings
    { managerResponseTimeout = responseTimeoutMicro 30_000_000 }
  backend <- mkForgejoBackend manager ForgejoConfig
    { upstreamBaseUrl = upstream
    , organization
    , accessToken = token
    }
  let application = mkApplication AppConfig
        { publicDirectory = staticDirectory
        , extraAllowedOrigins = origins
        } backend
      settings = setPort port $ setHost (fromString host) defaultSettings
  putStrLn $ "orbital-forge-backend: http://" <> host <> ":" <> show port
  putStrLn $ "orbital-forge-backend: upstream " <> upstream
  runSettings settings application

envString :: String -> String -> IO String
envString name fallback = fromMaybe fallback <$> lookupEnv name

envInt :: String -> Int -> IO Int
envInt name fallback = do
  value <- lookupEnv name
  pure $ fromMaybe fallback (value >>= readMaybe)

parseOrigins :: String -> [ByteString]
parseOrigins = filter (not . BS8.null) . map trim . BS8.split ',' . BS8.pack
 where
  trim = BS8.dropWhileEnd (== ' ') . BS8.dropWhile (== ' ')

discoverPublicDirectory :: IO (Maybe FilePath)
discoverPublicDirectory = do
  configured <- lookupEnv "FORGE_PUBLIC_DIR"
  case configured of
    Just directory -> pure (Just directory)
    Nothing -> do
      hasDist <- doesDirectoryExist "dist"
      pure $ if hasDist then Just "dist" else Nothing
