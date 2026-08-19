{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Orbital.Forge.Backend.Forgejo
  ( ForgejoConfig (..)
  , allowedForgejoPath
  , mkForgejoBackend
  ) where

import Control.Exception (finally, try)
import Data.Aeson qualified as Aeson
import Data.ByteString (ByteString)
import Data.ByteString qualified as BS
import Data.ByteString.Builder (Builder, byteString, toLazyByteString)
import Data.ByteString.Char8 qualified as BS8
import Data.ByteString.Lazy qualified as LBS
import Data.CaseInsensitive qualified as CI
import Data.Maybe (mapMaybe)
import Data.Text (Text)
import Data.Text qualified as Text
import Data.Text.Encoding qualified as TextEncoding
import Data.Text.Encoding.Error (lenientDecode)
import Network.HTTP.Client qualified as Client
import Network.HTTP.Types
  ( Status
  , hContentType
  , methodGet
  , methodHead
  , status403
  , status405
  , status502
  )
import Network.HTTP.Types.URI (encodePathSegments)
import Network.Wai
  ( Application
  , Request
  , Response
  , pathInfo
  , rawQueryString
  , requestHeaders
  , requestMethod
  , responseLBS
  , responseStream
  )
import Orbital.Forge.Application (stripProxyPrefix)
import Orbital.Forge.Backend (Backend (..))

data ForgejoConfig = ForgejoConfig
  { upstreamBaseUrl :: String
  , organization :: Text
  , accessToken :: Maybe ByteString
  }

mkForgejoBackend :: Client.Manager -> ForgejoConfig -> IO Backend
mkForgejoBackend manager config = do
  template <- Client.parseRequest (upstreamBaseUrl config)
  pure Backend
    { backendName = "forgejo"
    , backendApplication = proxyApplication manager config template
    }

proxyApplication :: Client.Manager -> ForgejoConfig -> Client.Request -> Application
proxyApplication manager config template request respond
  | requestMethod request `notElem` [methodGet, methodHead] =
      respond $ errorResponse status405 "only GET and HEAD are supported"
  | Nothing <- stripProxyPrefix (pathInfo request) =
      respond $ errorResponse status403 "invalid proxy route"
  | Just upstreamPath <- stripProxyPrefix (pathInfo request)
  , not (allowedForgejoPath (organization config) upstreamPath) =
      respond $ errorResponse status403 "upstream path is not allowed"
  | Just upstreamPath <- stripProxyPrefix (pathInfo request) = do
      let target = buildRequest config template upstreamPath request
      opened <- try (Client.responseOpen target manager)
      case opened of
        Left (exception :: Client.HttpException) ->
          respond $ errorResponse status502 (BS8.pack (show exception))
        Right upstream ->
          respond
            (responseStream
              (Client.responseStatus upstream)
              (filterResponseHeaders (Client.responseHeaders upstream))
              (streamBody (Client.responseBody upstream)))
            `finally` Client.responseClose upstream

allowedForgejoPath :: Text -> [Text] -> Bool
allowedForgejoPath expectedOrganization segments = case segments of
  ["orgs", actualOrganization, "repos"] -> actualOrganization == expectedOrganization
  "repos" : actualOrganization : repository : rest ->
    actualOrganization == expectedOrganization
      && not (Text.null repository)
      && all safeSegment (repository : rest)
  _ -> False

safeSegment :: Text -> Bool
safeSegment segment = not (Text.null segment) && segment /= "." && segment /= ".."

buildRequest :: ForgejoConfig -> Client.Request -> [Text] -> Request -> Client.Request
buildRequest config template upstreamPath incoming = template
  { Client.method = requestMethod incoming
  , Client.path = trimTrailingSlash (Client.path template) <> encodedPath upstreamPath
  , Client.queryString = rawQueryString incoming
  , Client.requestHeaders = authentication config <> forwardedRequestHeaders incoming
  , Client.requestBody = Client.RequestBodyBS ""
  , Client.redirectCount = 0
  , Client.decompress = const False
  }

encodedPath :: [Text] -> ByteString
encodedPath = LBS.toStrict . toLazyByteString . encodePathSegments

trimTrailingSlash :: ByteString -> ByteString
trimTrailingSlash value
  | value == "/" = ""
  | "/" `BS.isSuffixOf` value = BS.init value
  | otherwise = value

authentication :: ForgejoConfig -> [(CI.CI ByteString, ByteString)]
authentication config = case accessToken config of
  Just token -> [("Authorization", "token " <> token)]
  Nothing -> []

forwardedRequestHeaders :: Request -> [(CI.CI ByteString, ByteString)]
forwardedRequestHeaders request =
  ("User-Agent", "orbital-forge-backend/0.1")
    : mapMaybe keep (requestHeaders request)
 where
  keep header@(name, _)
    | CI.foldedCase name `elem` allowedRequestHeaders = Just header
    | otherwise = Nothing

allowedRequestHeaders :: [ByteString]
allowedRequestHeaders =
  [ "accept"
  , "range"
  , "if-match"
  , "if-none-match"
  , "if-modified-since"
  , "if-unmodified-since"
  , "if-range"
  ]

filterResponseHeaders :: [(CI.CI ByteString, ByteString)] -> [(CI.CI ByteString, ByteString)]
filterResponseHeaders = filter (not . blocked . CI.foldedCase . fst)
 where
  blocked name =
    name `elem`
      [ "connection"
      , "keep-alive"
      , "proxy-authenticate"
      , "proxy-authorization"
      , "te"
      , "trailer"
      , "transfer-encoding"
      , "upgrade"
      ]
      || "access-control-" `BS8.isPrefixOf` name

streamBody :: Client.BodyReader -> (Builder -> IO ()) -> IO () -> IO ()
streamBody reader send flush = go
 where
  go = do
    chunk <- Client.brRead reader
    if BS.null chunk
      then flush
      else send (byteString chunk) >> go

errorResponse :: Status -> ByteString -> Response
errorResponse status message =
  responseLBS status [(hContentType, "application/json; charset=utf-8")] $ Aeson.encode $ Aeson.object
    [ "error" Aeson..= TextEncoding.decodeUtf8With lenientDecode message ]
