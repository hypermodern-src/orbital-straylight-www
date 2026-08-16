{- |
Module      : Straylight.Web.Middleware.Sanitize
Description : A bounded Unicode storage floor at the request edge.

Adapted from @HyperModern.Server.Sanitize@ in Looking Local. This version adds
a hard JSON body limit before decoding so the reusable middleware does not rely
on every downstream contract having already bounded its request bodies.
-}
module Straylight.Web.Middleware.Sanitize (
    rejectHostileText,
    textIsClean,
) where

import Data.Aeson (Value (Array, Object, String), decode')
import Data.Aeson.Key qualified as Key
import Data.Aeson.KeyMap qualified as KeyMap
import Data.ByteString (ByteString)
import Data.ByteString qualified as ByteString
import Data.ByteString.Char8 qualified as ByteString8
import Data.ByteString.Lazy qualified as LBS
import Data.Char (toLower)
import Data.IORef (atomicModifyIORef', newIORef)
import Data.Text (Text)
import Data.Text qualified as Text
import Data.Text.Encoding (decodeUtf8')
import Network.HTTP.Types (hContentType, status400, status413)
import Network.Wai (
    Middleware,
    Request,
    RequestBodyLength (ChunkedBody, KnownLength),
    getRequestBodyChunk,
    pathInfo,
    queryString,
    requestBodyLength,
    requestHeaders,
    requestMethod,
    setRequestBodyChunks,
 )

import Straylight.Web.Middleware.Error (jsonErrorResponse)

{- | Unicode scalar values excluding NUL, DEL, and C0/C1 controls other than
tab, newline, and carriage return.
-}
textIsClean :: Text -> Bool
textIsClean = Text.all allowed
  where
    allowed character =
        character == '\t'
            || character == '\n'
            || character == '\r'
            || ( character >= ' '
                    && character /= '\DEL'
                    && not (character >= '\x80' && character <= '\x9f')
               )

bytesAreClean :: ByteString -> Bool
bytesAreClean bytes = case decodeUtf8' bytes of
    Left _ -> False
    Right text -> textIsClean text

valueIsClean :: Value -> Bool
valueIsClean value = case value of
    String text -> textIsClean text
    Array values -> all valueIsClean values
    Object values ->
        all (textIsClean . Key.toText) (KeyMap.keys values)
            && all valueIsClean (KeyMap.elems values)
    _ -> True

{- | Reject unstoreable path/query/JSON text and over-limit JSON bodies before
the application, authentication, or persistence layers run.
-}
rejectHostileText :: Int -> Middleware
rejectHostileText maxBodyBytes app request respond
    | not (all textIsClean (pathInfo request)) = rejectInvalid "path"
    | not (all queryItemClean (queryString request)) = rejectInvalid "query string"
    | hasJsonBody request =
        if declaredTooLarge request
            then rejectLarge
            else do
                bodyResult <- readBoundedBody maxBodyBytes request
                case bodyResult of
                    Left () -> rejectLarge
                    Right body ->
                        case decode' body of
                            Just document
                                | not (valueIsClean document) -> rejectInvalid "body"
                            _ -> replayBody body app request respond
    | otherwise = app request respond
  where
    queryItemClean (key, value) = bytesAreClean key && maybe True bytesAreClean value
    declaredTooLarge current = case requestBodyLength current of
        KnownLength length' -> length' > fromIntegral maxBodyBytes
        ChunkedBody -> False
    rejectInvalid site =
        respond
            ( jsonErrorResponse
                status400
                "invalid_text"
                ("unstorable or control characters in " <> site)
            )
    rejectLarge =
        respond
            ( jsonErrorResponse
                status413
                "payload_too_large"
                "JSON request body exceeds the configured limit"
            )

hasJsonBody :: Request -> Bool
hasJsonBody request =
    requestMethod request `elem` (["POST", "PATCH", "PUT", "DELETE"] :: [ByteString])
        && maybe False isJsonContentType (lookup hContentType (requestHeaders request))
  where
    isJsonContentType = ByteString.isPrefixOf "application/json" . ByteString8.map toLower

readBoundedBody :: Int -> Request -> IO (Either () LBS.ByteString)
readBoundedBody limit request = go 0 []
  where
    go consumed chunks = do
        chunk <- getRequestBodyChunk request
        if ByteString.null chunk
            then pure (Right (LBS.fromChunks (reverse chunks)))
            else
                if ByteString.length chunk > limit - consumed
                    then pure (Left ())
                    else go (consumed + ByteString.length chunk) (chunk : chunks)

replayBody :: LBS.ByteString -> Middleware
replayBody body app request respond = do
    chunks <- newIORef (LBS.toChunks body)
    let popChunk = atomicModifyIORef' chunks $ \remaining ->
            case remaining of
                [] -> ([], ByteString.empty)
                chunk : rest -> (rest, chunk)
    app (setRequestBodyChunks popChunk request) respond
