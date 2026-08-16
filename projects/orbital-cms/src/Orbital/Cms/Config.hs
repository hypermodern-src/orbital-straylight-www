module Orbital.Cms.Config (
    Config (..),
    ConfigError (..),
    loadConfig,
) where

import Data.ByteString (ByteString)
import Data.ByteString.Char8 qualified as ByteString
import Data.Text (Text)
import Data.Text qualified as Text
import System.Environment (lookupEnv)
import Text.Read (readMaybe)

data Config = Config
    { configDatabaseUrl :: ByteString
    , configEditorToken :: Maybe ByteString
    , configEditorActor :: Text
    , configHost :: String
    , configPort :: Int
    , configShutdownSeconds :: Int
    , configDatabasePoolSize :: Int
    }
    deriving stock (Eq)

newtype ConfigError = ConfigError Text
    deriving stock (Eq, Show)

loadConfig :: IO (Either [ConfigError] Config)
loadConfig = do
    databaseUrl <- lookupEnv "DATABASE_URL"
    editorToken <- lookupEnv "ORBITAL_CMS_EDITOR_TOKEN"
    editorActor <- lookupEnv "ORBITAL_CMS_EDITOR_ID"
    host <- lookupEnv "HOST"
    port <- lookupEnv "PORT"
    shutdownSeconds <- lookupEnv "SHUTDOWN_TIMEOUT_SECONDS"
    poolSize <- lookupEnv "DATABASE_POOL_SIZE"
    pure $ do
        parsedDatabaseUrl <- required "DATABASE_URL" databaseUrl
        parsedToken <- validateToken editorToken
        parsedActor <- nonEmpty "ORBITAL_CMS_EDITOR_ID" (maybe "bootstrap" id editorActor)
        parsedPort <- boundedInt "PORT" 1 65535 8090 port
        parsedShutdown <- boundedInt "SHUTDOWN_TIMEOUT_SECONDS" 1 300 30 shutdownSeconds
        parsedPoolSize <- boundedInt "DATABASE_POOL_SIZE" 1 64 8 poolSize
        pure
            Config
                { configDatabaseUrl = ByteString.pack parsedDatabaseUrl
                , configEditorToken = ByteString.pack <$> parsedToken
                , configEditorActor = Text.pack parsedActor
                , configHost = maybe "127.0.0.1" id host
                , configPort = parsedPort
                , configShutdownSeconds = parsedShutdown
                , configDatabasePoolSize = parsedPoolSize
                }

required :: Text -> Maybe String -> Either [ConfigError] String
required name = \case
    Nothing -> Left [ConfigError (name <> " is required")]
    Just value -> nonEmpty name value

nonEmpty :: Text -> String -> Either [ConfigError] String
nonEmpty name value
    | null value = Left [ConfigError (name <> " must not be empty")]
    | otherwise = Right value

validateToken :: Maybe String -> Either [ConfigError] (Maybe String)
validateToken Nothing = Right Nothing
validateToken (Just token)
    | ByteString.length (ByteString.pack token) < 32 =
        Left [ConfigError "ORBITAL_CMS_EDITOR_TOKEN must contain at least 32 bytes"]
    | otherwise = Right (Just token)

boundedInt :: Text -> Int -> Int -> Int -> Maybe String -> Either [ConfigError] Int
boundedInt _ _ _ fallback Nothing = Right fallback
boundedInt name lower upper _ (Just raw) = case readMaybe raw of
    Just value | value >= lower && value <= upper -> Right value
    _ -> Left [ConfigError (name <> " must be an integer from " <> showText lower <> " to " <> showText upper)]

showText :: (Show value) => value -> Text
showText = Text.pack . show
