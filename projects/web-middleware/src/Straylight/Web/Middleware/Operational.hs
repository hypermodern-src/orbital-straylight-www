module Straylight.Web.Middleware.Operational (
    operationalEndpoints,
) where

import Data.ByteString.Lazy (ByteString)
import Network.HTTP.Types (Status, methodGet, status200, status405, status503)
import Network.HTTP.Types.Header (hAllow, hCacheControl, hContentType)
import Network.Wai (Application, Response, mapResponseHeaders, pathInfo, requestMethod, responseLBS)

import Straylight.Web.Middleware.Error (jsonErrorResponse)
import Straylight.Web.Middleware.Runtime (Readiness (..), Runtime, readReadiness)

-- | Reserve liveness and readiness ahead of the product router.
operationalEndpoints :: Runtime -> Application -> Application
operationalEndpoints runtime app request respond = case pathInfo request of
    ["healthz"] -> serveProbe health
    ["readyz"] -> do
        readiness <- readReadiness runtime
        serveProbe (ready readiness)
    _ -> app request respond
  where
    serveProbe result
        | requestMethod request == methodGet = respond (uncurry plainResponse result)
        | otherwise =
            respond
                ( addAllow
                    (jsonErrorResponse status405 "method_not_allowed" "only GET is supported")
                )
    health = (status200, "ok\n")
    ready Ready = (status200, "ready\n")
    ready Warming = (status503, "warming\n")
    ready Draining = (status503, "draining\n")

plainResponse :: Status -> ByteString -> Response
plainResponse status body =
    responseLBS
        status
        [ (hContentType, "text/plain; charset=utf-8")
        , (hCacheControl, "no-store")
        ]
        body

addAllow :: Response -> Response
addAllow = mapResponseHeaders ((hAllow, "GET") :)
