{-# LANGUAGE OverloadedStrings #-}

module Orbital.Forge.Application
  ( AppConfig (..)
  , defaultProxyPrefix
  , mkApplication
  , originAllowed
  , stripProxyPrefix
  ) where

import Data.Aeson qualified as Aeson
import Data.ByteString (ByteString)
import Data.ByteString.Char8 qualified as BS8
import Data.CaseInsensitive qualified as CI
import Data.Text (Text)
import Network.HTTP.Types
  ( Status
  , hContentType
  , methodOptions
  , status200
  , status204
  , status403
  , status404
  )
import Network.Wai
  ( Application
  , Request
  , Response
  , mapResponseHeaders
  , pathInfo
  , rawPathInfo
  , requestHeaders
  , requestMethod
  , responseLBS
  )
import Network.Wai.Application.Static
  ( defaultWebAppSettings
  , staticApp
  )
import Orbital.Forge.Backend (Backend (..))

data AppConfig = AppConfig
  { publicDirectory :: Maybe FilePath
  , extraAllowedOrigins :: [ByteString]
  }

defaultProxyPrefix :: [Text]
defaultProxyPrefix = ["api", "forge", "v1"]

stripProxyPrefix :: [Text] -> Maybe [Text]
stripProxyPrefix value
  | defaultProxyPrefix == take (length defaultProxyPrefix) value =
      Just (drop (length defaultProxyPrefix) value)
  | otherwise = Nothing

mkApplication :: AppConfig -> Backend -> Application
mkApplication config backend request respond
  | pathInfo request == ["healthz"] =
      respond $ json status200 $ Aeson.object
        [ "status" Aeson..= ("ok" :: Text)
        , "backend" Aeson..= BS8.unpack (backendName backend)
        ]
  | Just _ <- stripProxyPrefix (pathInfo request) =
      serveApi config backend request respond
  | otherwise = case publicDirectory config of
      Just directory ->
        let staticRequest = if null (pathInfo request)
              then request { pathInfo = ["index.html"], rawPathInfo = "/index.html" }
              else request
        in staticApp (defaultWebAppSettings directory) staticRequest respond
      Nothing -> respond $ json status404 $ Aeson.object
        [ "error" Aeson..= ("not found" :: Text) ]

serveApi :: AppConfig -> Backend -> Application
serveApi config backend request respond
  | requestMethod request == methodOptions =
      case requestOrigin request of
        Just origin
          | originAllowed (extraAllowedOrigins config) origin ->
              respond $ responseLBS status204 (corsHeaders origin) ""
        _ -> respond $ json status403 $ Aeson.object
          [ "error" Aeson..= ("origin not allowed" :: Text) ]
  | otherwise = backendApplication backend request $ \response ->
      respond $ case requestOrigin request of
        Just origin
          | originAllowed (extraAllowedOrigins config) origin ->
              mapResponseHeaders (replaceCorsHeaders origin) response
        _ -> response

requestOrigin :: Request -> Maybe ByteString
requestOrigin request = lookup "Origin" (requestHeaders request)

originAllowed :: [ByteString] -> ByteString -> Bool
originAllowed configured origin =
  origin `elem` configured
    || origin == "https://orbital-forge-iota.vercel.app"
    || origin == "https://forge.orbital.foo"
    || isVercelPreview origin
    || isLocalDevelopment origin

isVercelPreview :: ByteString -> Bool
isVercelPreview origin =
  "https://orbital-forge-" `BS8.isPrefixOf` origin
    && ".vercel.app" `BS8.isSuffixOf` origin

isLocalDevelopment :: ByteString -> Bool
isLocalDevelopment origin =
  any (`BS8.isPrefixOf` origin)
    [ "http://localhost:"
    , "http://127.0.0.1:"
    , "http://[::1]:"
    ]
    || origin `elem` ["http://localhost", "http://127.0.0.1", "http://[::1]"]

replaceCorsHeaders :: ByteString -> [(CI.CI ByteString, ByteString)] -> [(CI.CI ByteString, ByteString)]
replaceCorsHeaders origin headers =
  filter (not . isCorsHeader . fst) headers <> corsHeaders origin

isCorsHeader :: CI.CI ByteString -> Bool
isCorsHeader name =
  "access-control-" `BS8.isPrefixOf` CI.foldedCase name
    || CI.foldedCase name == "vary"

corsHeaders :: ByteString -> [(CI.CI ByteString, ByteString)]
corsHeaders origin =
  [ ("Access-Control-Allow-Origin", origin)
  , ("Access-Control-Allow-Methods", "GET, HEAD, OPTIONS")
  , ("Access-Control-Allow-Headers", "Content-Type, Range")
  , ("Access-Control-Expose-Headers", "Content-Length, Content-Range, ETag, Last-Modified")
  , ("Access-Control-Allow-Private-Network", "true")
  , ("Vary", "Origin, Access-Control-Request-Private-Network")
  ]

json :: Aeson.ToJSON value => Status -> value -> Response
json status value = responseLBS status [(hContentType, "application/json; charset=utf-8")] (Aeson.encode value)
