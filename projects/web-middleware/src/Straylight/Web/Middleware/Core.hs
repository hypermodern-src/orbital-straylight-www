module Straylight.Web.Middleware.Core (
    middleware,
    requestIdFromRequest,
) where

import Control.Exception (AsyncException, SomeException, fromException, handleJust)
import Data.ByteString (ByteString)
import Data.ByteString qualified as ByteString
import Data.Text (Text)
import Data.Text.Encoding (decodeUtf8With, encodeUtf8)
import Data.Text.Encoding.Error (lenientDecode)
import Data.Time (diffUTCTime, getCurrentTime)
import Data.UUID qualified as UUID
import Data.UUID.V4 qualified as UUIDV4
import Data.Vault.Lazy qualified as Vault
import Data.Word (Word8)
import Network.HTTP.Types (HeaderName, ResponseHeaders, hContentType, status404, status500, statusCode)
import Network.Wai (
    Middleware,
    Request,
    mapResponseHeaders,
    rawPathInfo,
    requestHeaders,
    requestMethod,
    responseStatus,
    vault,
 )

import Straylight.Web.Middleware.Error (jsonErrorResponse)
import Straylight.Web.Middleware.Operational (operationalEndpoints)
import Straylight.Web.Middleware.Runtime (
    MiddlewareSettings (..),
    RequestObservation (..),
    Runtime,
    runtimeRequestIdKey,
    runtimeSettings,
 )
import Straylight.Web.Middleware.Sanitize (rejectHostileText)

requestIdHeader :: HeaderName
requestIdHeader = "X-Request-Id"

{- | The complete policy stack, outermost first. The operational endpoints are
below every policy so they receive the same IDs, logs, and response headers
as product routes.
-}
middleware :: Runtime -> Middleware
middleware runtime app =
    requestIdMiddleware
        runtime
        ( requestLogger
            runtime
            ( securityHeadersMiddleware
                runtime
                ( exceptionBoundary
                    runtime
                    ( bareJsonContentType
                        ( rejectTrailingSlash
                            ( rejectHostileText
                                (middlewareMaxJsonBodyBytes (runtimeSettings runtime))
                                (operationalEndpoints runtime app)
                            )
                        )
                    )
                )
            )
        )

-- | Read the canonical ID installed into the request vault.
requestIdFromRequest :: Runtime -> Request -> Maybe Text
requestIdFromRequest runtime request =
    Vault.lookup (runtimeRequestIdKey runtime) (vault request)

requestIdMiddleware :: Runtime -> Middleware
requestIdMiddleware runtime app request respond = do
    requestId <- chooseRequestId request
    let request' = request{vault = Vault.insert (runtimeRequestIdKey runtime) requestId (vault request)}
    app request' (respond . mapResponseHeaders (replaceHeader requestIdHeader (encodeText requestId)))

chooseRequestId :: Request -> IO Text
chooseRequestId request = case lookup requestIdHeader (requestHeaders request) of
    Just candidate | validRequestId candidate -> pure (decodeUtf8With lenientDecode candidate)
    _ -> UUID.toText <$> UUIDV4.nextRandom

validRequestId :: ByteString -> Bool
validRequestId value =
    not (ByteString.null value)
        && ByteString.length value <= 128
        && ByteString.all safe value
  where
    safe byte =
        (byte >= 48 && byte <= 57)
            || (byte >= 65 && byte <= 90)
            || (byte >= 97 && byte <= 122)
            || byte `elem` ([45, 46, 47, 58, 95] :: [Word8])

encodeText :: Text -> ByteString
encodeText = encodeUtf8

requestLogger :: Runtime -> Middleware
requestLogger runtime app request respond = do
    started <- getCurrentTime
    app request $ \response -> do
        ended <- getCurrentTime
        let duration = round (realToFrac (diffUTCTime ended started) * 1000 :: Double)
            observation =
                RequestObservation
                    { observationRequestId = maybe "unknown" id (requestIdFromRequest runtime request)
                    , observationMethod = decodeUtf8With lenientDecode (requestMethod request)
                    , observationPath = decodeUtf8With lenientDecode (rawPathInfo request)
                    , observationStatus = statusCode (responseStatus response)
                    , observationDurationMilliseconds = duration
                    }
        ignoreSynchronous (middlewareObserveRequest (runtimeSettings runtime) observation)
        respond response

securityHeadersMiddleware :: Runtime -> Middleware
securityHeadersMiddleware runtime app request respond =
    app request (respond . mapResponseHeaders addMissing)
  where
    addMissing existing = foldr addIfMissing existing (middlewareSecurityHeaders (runtimeSettings runtime))
    addIfMissing header@(name, _) headers
        | any ((== name) . fst) headers = headers
        | otherwise = header : headers

exceptionBoundary :: Runtime -> Middleware
exceptionBoundary runtime app request respond =
    handleJust synchronous onException (app request respond)
  where
    onException exception = do
        ignoreSynchronous (middlewareReportException (runtimeSettings runtime) request exception)
        respond (jsonErrorResponse status500 "server_error" "internal server error")

synchronous :: SomeException -> Maybe SomeException
synchronous exception = case (fromException exception :: Maybe AsyncException) of
    Just _ -> Nothing
    Nothing -> Just exception

ignoreSynchronous :: IO () -> IO ()
ignoreSynchronous = handleJust synchronous (const (pure ()))

rejectTrailingSlash :: Middleware
rejectTrailingSlash app request respond
    | ByteString.isSuffixOf "/" path && path /= "/" =
        respond (jsonErrorResponse status404 "not_found" "resource not found")
    | otherwise = app request respond
  where
    path = rawPathInfo request

bareJsonContentType :: Middleware
bareJsonContentType app request respond =
    app request (respond . mapResponseHeaders (fmap normalize))
  where
    normalize (name, value)
        | name == hContentType && ByteString.isPrefixOf "application/json" value =
            (name, "application/json")
        | otherwise = (name, value)

replaceHeader :: HeaderName -> ByteString -> ResponseHeaders -> ResponseHeaders
replaceHeader name value headers = (name, value) : filter ((/= name) . fst) headers
