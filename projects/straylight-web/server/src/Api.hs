-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                                    // straylight-api // api
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--
-- Combined Servant API for all Straylight products.
--
-- This module re-exports all product APIs and provides a combined API type
-- for serving all products from a single server with OpenAPI spec endpoints.
--
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module Api
    ( -- * Combined API
      StraylightAPI
    , straylightApi
    
      -- * OpenAPI Endpoints
    , OpenApiEndpoints
    
      -- * Re-exports
    , module Api.Types
    , module Api.OpenApi
    
      -- * Product API types (import individually for types)
    , CacheAPI
    , BuildAPI
    , ConvergeAPI
    , ConfirmAPI
    , ForgeAPI
    , PublishAPI
    , CodeAPI
    , WorkAPI
    , ProxyAPI
    , BoostAPI
    ) where

import Data.Aeson (Value)
import Data.Proxy
import Servant

-- Core types
import Api.Types
import Api.OpenApi

-- sensenet products
import Api.Sensenet.Cache
import Api.Sensenet.Build
import Api.Sensenet.Converge
import Api.Sensenet.Confirm
import Api.Sensenet.Forge
import Api.Sensenet.Publish

-- omega products
import Api.Omega.Code
import Api.Omega.Work
import Api.Omega.Proxy
import Api.Omega.Boost


-- ═══════════════════════════════════════════════════════════════════════════
-- // openapi endpoints //
-- ═══════════════════════════════════════════════════════════════════════════

-- | OpenAPI spec endpoints for each product
type OpenApiEndpoints =
    -- sensenet specs
    "openapi" :> "sensenet" :> "cache.json" :> Get '[JSON] Value
        :<|> "openapi" :> "sensenet" :> "build.json" :> Get '[JSON] Value
        :<|> "openapi" :> "sensenet" :> "converge.json" :> Get '[JSON] Value
        :<|> "openapi" :> "sensenet" :> "confirm.json" :> Get '[JSON] Value
        :<|> "openapi" :> "sensenet" :> "forge.json" :> Get '[JSON] Value
        :<|> "openapi" :> "sensenet" :> "publish.json" :> Get '[JSON] Value
    -- omega specs
        :<|> "openapi" :> "omega" :> "code.json" :> Get '[JSON] Value
        :<|> "openapi" :> "omega" :> "work.json" :> Get '[JSON] Value
        :<|> "openapi" :> "omega" :> "proxy.json" :> Get '[JSON] Value
        :<|> "openapi" :> "omega" :> "boost.json" :> Get '[JSON] Value
    -- combined spec
        :<|> "openapi.json" :> Get '[JSON] Value
    -- spec index
        :<|> "openapi" :> Get '[JSON] Value


-- ═══════════════════════════════════════════════════════════════════════════
-- // combined api //
-- ═══════════════════════════════════════════════════════════════════════════

-- | Combined API for all Straylight products
type StraylightAPI =
    -- OpenAPI spec endpoints
    OpenApiEndpoints
    -- sensenet products
        :<|> CacheAPI
        :<|> BuildAPI
        :<|> ConvergeAPI
        :<|> ConfirmAPI
        :<|> ForgeAPI
        :<|> PublishAPI
    -- omega products
        :<|> CodeAPI
        :<|> WorkAPI
        :<|> ProxyAPI
        :<|> BoostAPI


straylightApi :: Proxy StraylightAPI
straylightApi = Proxy
