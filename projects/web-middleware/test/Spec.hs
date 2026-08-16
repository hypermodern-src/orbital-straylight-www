module Main (
    main,
) where

import Control.Exception (throwIO)
import Data.Aeson (decode)
import Data.ByteString (ByteString)
import Data.ByteString qualified as ByteString
import Data.ByteString.Lazy qualified as LBS
import Data.IORef (newIORef, readIORef, writeIORef)
import Data.Text (Text)
import Data.Text qualified as Text
import Data.Text.Encoding (decodeUtf8)
import Network.HTTP.Types (HeaderName, hContentType, methodGet, methodPost, status200, status400, status404, status413, status500, status503)
import Network.Wai (Application, Request (..), lazyRequestBody, responseLBS)
import Network.Wai.Test (SRequest (SRequest), SResponse (..), defaultRequest, request, runSession, srequest)
import Straylight.Web.Middleware qualified as Web
import Straylight.Web.Middleware.Config (ConfigError, assembleServerConfig)
import Test.Hspec (Spec, describe, hspec, it, shouldBe, shouldNotBe, shouldSatisfy)

main :: IO ()
main = hspec spec

spec :: Spec
spec = do
    describe "request policy" $ do
        it "preserves a safe inbound request ID and hardens the response" $ do
            runtime <- quietRuntime Web.defaultMiddlewareSettings
            response <- runGet runtime "/" "" [("X-Request-Id", "edge-123")]
            lookup "X-Request-Id" (simpleHeaders response) `shouldBe` Just "edge-123"
            lookup "X-Content-Type-Options" (simpleHeaders response) `shouldBe` Just "nosniff"
            lookup "X-Frame-Options" (simpleHeaders response) `shouldBe` Just "DENY"

        it "replaces an unsafe inbound request ID" $ do
            runtime <- quietRuntime Web.defaultMiddlewareSettings
            response <- runGet runtime "/" "" [("X-Request-Id", "contains spaces")]
            lookup "X-Request-Id" (simpleHeaders response) `shouldSatisfy` maybe False (not . LBS.null . LBS.fromStrict)
            lookup "X-Request-Id" (simpleHeaders response) `shouldNotBe` Just "contains spaces"

        it "does not log query strings" $ do
            observed <- newIORef Nothing
            let settings' =
                    Web.defaultMiddlewareSettings
                        { Web.middlewareObserveRequest = writeIORef observed . Just
                        }
            runtime <-
                Web.newRuntime
                    settings'
                        { Web.middlewareReportException = \_ _ -> pure ()
                        }
            _ <- runGet runtime "/search" "?token=secret" []
            observation <- readIORef observed
            fmap Web.observationPath observation `shouldBe` Just "/search"

        it "turns synchronous application exceptions into opaque 500 errors" $ do
            runtime <- quietRuntime Web.defaultMiddlewareSettings
            response <- runSession (request defaultRequest) (Web.middleware runtime explodingApp)
            simpleStatus response `shouldBe` status500
            decode (simpleBody response)
                `shouldBe` Just (Web.ApiError "server_error" "internal server error" Nothing)
            simpleBody response `shouldSatisfy` not . ByteString.isInfixOf "secret" . LBS.toStrict

        it "rejects non-canonical trailing slashes" $ do
            runtime <- quietRuntime Web.defaultMiddlewareSettings
            response <- runGet runtime "/thing/" "" []
            simpleStatus response `shouldBe` status404

    describe "Unicode and body floor" $ do
        it "replays clean JSON to the application" $ do
            runtime <- quietRuntime Web.defaultMiddlewareSettings
            response <- runJson runtime "{\"message\":\"hello\"}"
            simpleStatus response `shouldBe` status200
            simpleBody response `shouldBe` "{\"message\":\"hello\"}"

        it "rejects hostile control characters in decoded JSON" $ do
            runtime <- quietRuntime Web.defaultMiddlewareSettings
            response <- runJson runtime "{\"message\":\"\\u0000\"}"
            simpleStatus response `shouldBe` status400
            decode (simpleBody response)
                `shouldBe` Just (Web.ApiError "invalid_text" "unstorable or control characters in body" Nothing)

        it "rejects JSON above the configured limit" $ do
            let settings' = Web.defaultMiddlewareSettings{Web.middlewareMaxJsonBodyBytes = 8}
            runtime <- quietRuntime settings'
            response <- runJson runtime "{\"message\":\"too long\"}"
            simpleStatus response `shouldBe` status413

    describe "operational lifecycle" $ do
        it "stays live while readiness moves from warming through ready to draining" $ do
            runtime <- quietRuntime Web.defaultMiddlewareSettings
            warming <- runGet runtime "/readyz" "" []
            simpleStatus warming `shouldBe` status503
            simpleBody warming `shouldBe` "warming\n"

            Web.markReady runtime
            ready <- runGet runtime "/readyz" "" []
            simpleStatus ready `shouldBe` status200
            simpleBody ready `shouldBe` "ready\n"

            Web.beginDrain runtime
            Web.markReady runtime
            draining <- runGet runtime "/readyz" "" []
            simpleStatus draining `shouldBe` status503
            simpleBody draining `shouldBe` "draining\n"

            live <- runGet runtime "/healthz" "" []
            simpleStatus live `shouldBe` status200

    describe "configuration" $ do
        it "accumulates every invalid deployment knob" $ do
            let result = assembleServerConfig (Just "") (Just "0") (Just "nope") (Just "999999999")
            result `shouldSatisfy` hasFaultCount 4

quietRuntime :: Web.MiddlewareSettings -> IO Web.Runtime
quietRuntime settings' =
    Web.newRuntime
        settings'
            { Web.middlewareObserveRequest = const (pure ())
            , Web.middlewareReportException = \_ _ -> pure ()
            }

runGet :: Web.Runtime -> LBS.ByteString -> LBS.ByteString -> [(HeaderName, ByteString)] -> IO SResponse
runGet runtime path query headers =
    runSession
        ( request
            defaultRequest
                { requestMethod = methodGet
                , rawPathInfo = LBS.toStrict path
                , pathInfo = pathSegments path
                , rawQueryString = LBS.toStrict query
                , requestHeaders = headers
                }
        )
        (Web.middleware runtime okApp)

runJson :: Web.Runtime -> LBS.ByteString -> IO SResponse
runJson runtime body =
    runSession
        ( srequest
            ( SRequest
                defaultRequest
                    { requestMethod = methodPost
                    , rawPathInfo = "/echo"
                    , pathInfo = ["echo"]
                    , requestHeaders = [(hContentType, "application/json")]
                    }
                body
            )
        )
        (Web.middleware runtime echoApp)

pathSegments :: LBS.ByteString -> [Text]
pathSegments path = case Text.stripPrefix "/" (decodeUtf8 (LBS.toStrict path)) of
    Just "" -> []
    Just rest -> Text.splitOn "/" rest
    Nothing -> []

okApp :: Application
okApp _request respond = respond (responseLBS status200 [(hContentType, "application/json; charset=utf-8")] "{}")

echoApp :: Application
echoApp request' respond = do
    body <- lazyRequestBody request'
    respond (responseLBS status200 [(hContentType, "application/json")] body)

explodingApp :: Application
explodingApp _request _respond = throwIO (userError "secret internal detail")

hasFaultCount :: Int -> Either [ConfigError] a -> Bool
hasFaultCount expected (Left errors) = length errors == expected
hasFaultCount _ (Right _) = False
