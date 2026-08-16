-- | Public facade for the Straylight HTTP policy boundary.
module Straylight.Web.Middleware (
    ApiError (..),
    MiddlewareSettings (..),
    Readiness (..),
    RequestObservation (..),
    Runtime,
    apiErrorResponse,
    beginDrain,
    defaultMiddlewareSettings,
    defaultSecurityHeaders,
    jsonErrorResponse,
    markReady,
    markWarming,
    middleware,
    newRuntime,
    readReadiness,
    requestIdFromRequest,
    stderrExceptionReporter,
    stderrJsonObserver,
) where

import Straylight.Web.Middleware.Core (middleware, requestIdFromRequest)
import Straylight.Web.Middleware.Error (ApiError (..), apiErrorResponse, jsonErrorResponse)
import Straylight.Web.Middleware.Runtime (
    MiddlewareSettings (..),
    Readiness (..),
    RequestObservation (..),
    Runtime,
    beginDrain,
    defaultMiddlewareSettings,
    defaultSecurityHeaders,
    markReady,
    markWarming,
    newRuntime,
    readReadiness,
    stderrExceptionReporter,
    stderrJsonObserver,
 )
