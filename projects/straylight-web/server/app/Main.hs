-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                               // straylight-api // app/main
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--
-- Server entry point. Serves OpenAPI specs for all Straylight products.
--
-- Usage:
--   straylight-api                    # Run server on port 8080
--   straylight-api --port 3000        # Run on custom port
--   straylight-api --export           # Export all specs to files
--
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module Main where

import Data.Aeson (Value, encode, toJSON)
import Data.ByteString.Lazy qualified as BSL
import Data.Text (Text)
import Data.Text qualified as T
import Network.HTTP.Types (status200)
import Network.Wai
import Network.Wai.Handler.Warp
import Servant
import System.Environment (getArgs)
import System.IO

import Api
import Api.OpenApi


-- ═══════════════════════════════════════════════════════════════════════════
-- // main //
-- ═══════════════════════════════════════════════════════════════════════════

main :: IO ()
main = do
    args <- getArgs
    case args of
        ["--export"] -> exportAllSpecs
        ["--export", dir] -> exportAllSpecsTo dir
        ["--port", portStr] -> runServer (read portStr)
        _ -> runServer 8080


-- ═══════════════════════════════════════════════════════════════════════════
-- // server //
-- ═══════════════════════════════════════════════════════════════════════════

runServer :: Port -> IO ()
runServer port = do
    putStrLn $ "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    putStrLn $ "                                      // straylight-api"
    putStrLn $ "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    putStrLn ""
    putStrLn $ "OpenAPI 3.1.0 specs for all Straylight products"
    putStrLn ""
    putStrLn "Endpoints:"
    putStrLn "  GET /openapi.json               Combined spec"
    putStrLn "  GET /openapi                    Spec index"
    putStrLn ""
    putStrLn "  GET /openapi/sensenet/cache.json"
    putStrLn "  GET /openapi/sensenet/build.json"
    putStrLn "  GET /openapi/sensenet/converge.json"
    putStrLn "  GET /openapi/sensenet/confirm.json"
    putStrLn "  GET /openapi/sensenet/forge.json"
    putStrLn "  GET /openapi/sensenet/publish.json"
    putStrLn ""
    putStrLn "  GET /openapi/omega/code.json"
    putStrLn "  GET /openapi/omega/work.json"
    putStrLn "  GET /openapi/omega/proxy.json"
    putStrLn "  GET /openapi/omega/boost.json"
    putStrLn ""
    putStrLn $ "Server running on port " ++ show port
    putStrLn ""
    run port app


app :: Application
app = corsMiddleware $ serve (Proxy :: Proxy OpenApiEndpointsOnly) openApiHandlers

-- Simple CORS middleware
corsMiddleware :: Middleware
corsMiddleware baseApp req respond = 
    case requestMethod req of
        "OPTIONS" -> respond $ responseLBS status200 corsHeaders ""
        _ -> baseApp req $ \response -> 
            respond $ mapResponseHeaders (++ corsHeaders) response
  where
    corsHeaders =
        [ ("Access-Control-Allow-Origin", "*")
        , ("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
        , ("Access-Control-Allow-Headers", "Content-Type, Authorization")
        , ("Access-Control-Max-Age", "86400")
        ]

-- Only serve OpenAPI endpoints (no actual API handlers yet)
type OpenApiEndpointsOnly = OpenApiEndpoints

openApiHandlers :: Server OpenApiEndpointsOnly
openApiHandlers =
    -- sensenet specs
    pure (toJSON cacheOpenApi)
        :<|> pure (toJSON buildOpenApi)
        :<|> pure (toJSON convergeOpenApi)
        :<|> pure (toJSON confirmOpenApi)
        :<|> pure (toJSON forgeOpenApi)
        :<|> pure (toJSON publishOpenApi)
    -- omega specs
        :<|> pure (toJSON codeOpenApi)
        :<|> pure (toJSON workOpenApi)
        :<|> pure (toJSON proxyOpenApi)
        :<|> pure (toJSON boostOpenApi)
    -- combined
        :<|> pure (toJSON allOpenApi)
    -- index
        :<|> pure specIndex


specIndex :: Value
specIndex = toJSON $ map specEntry allProductSpecs
  where
    specEntry spec = 
        [ ("name" :: Text, toJSON $ specName spec)
        , ("title", toJSON $ specTitle spec)
        , ("description", toJSON $ specDescription spec)
        , ("version", toJSON $ specVersion spec)
        , ("path", toJSON $ specPath spec)
        ]


-- ═══════════════════════════════════════════════════════════════════════════
-- // export //
-- ═══════════════════════════════════════════════════════════════════════════

exportAllSpecs :: IO ()
exportAllSpecs = exportAllSpecsTo "."

exportAllSpecsTo :: FilePath -> IO ()
exportAllSpecsTo dir = do
    putStrLn "Exporting OpenAPI specs..."
    putStrLn ""
    
    -- sensenet
    writeSpec (dir ++ "/sensenet-cache-openapi.json") cacheOpenApi
    writeSpec (dir ++ "/sensenet-build-openapi.json") buildOpenApi
    writeSpec (dir ++ "/sensenet-converge-openapi.json") convergeOpenApi
    writeSpec (dir ++ "/sensenet-confirm-openapi.json") confirmOpenApi
    writeSpec (dir ++ "/sensenet-forge-openapi.json") forgeOpenApi
    writeSpec (dir ++ "/sensenet-publish-openapi.json") publishOpenApi
    
    -- omega
    writeSpec (dir ++ "/omega-code-openapi.json") codeOpenApi
    writeSpec (dir ++ "/omega-work-openapi.json") workOpenApi
    writeSpec (dir ++ "/omega-proxy-openapi.json") proxyOpenApi
    writeSpec (dir ++ "/omega-boost-openapi.json") boostOpenApi
    
    -- combined
    writeSpec (dir ++ "/straylight-openapi.json") allOpenApi
    
    putStrLn ""
    putStrLn "Done! Exported 11 OpenAPI specs."
  where
    writeSpec path spec = do
        BSL.writeFile path (encode spec)
        putStrLn $ "  " ++ path
