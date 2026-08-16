-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                              // straylight-api // api/types
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--
-- Shared data models used across all Straylight product APIs. These types
-- form the foundation for consistent API design across the platform.
--
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module Api.Types
    ( -- * Common Types
      Health (..)
    , ApiInfo (..)
    , Pagination (..)
    , PaginatedResponse (..)
    , ErrorResponse (..)
    , SuccessResponse (..)
    
      -- * Authentication
    , ApiKey (..)
    , AuthToken (..)
    , AuthHeader
    
      -- * Timestamps
    , Timestamp (..)
    , TimeRange (..)
    
      -- * IDs
    , ResourceId (..)
    , UserId (..)
    , OrganizationId (..)
    
      -- * Common API Patterns
    , HealthAPI
    , InfoAPI
    ) where

import Data.Aeson (FromJSON, ToJSON, Value)
import Data.Map.Strict (Map)
import Data.OpenApi (ToSchema (..), ToParamSchema (..), NamedSchema (..), Schema)
import qualified Data.OpenApi as OpenApi
import Data.Proxy (Proxy (..))
import Data.Text (Text)
import Data.Time (UTCTime)
import GHC.Generics
import Servant
import Servant.OpenApi ()


-- ═══════════════════════════════════════════════════════════════════════════
-- // orphan instances //
-- ═══════════════════════════════════════════════════════════════════════════

-- | ToSchema instance for aeson Value (represents arbitrary JSON)
instance ToSchema Value where
    declareNamedSchema _ = pure $ NamedSchema (Just "JSON") $ 
        mempty { OpenApi._schemaDescription = Just "Arbitrary JSON value" }


-- ═══════════════════════════════════════════════════════════════════════════
-- // health //
-- ═══════════════════════════════════════════════════════════════════════════

data Health = Health
    { healthy :: Bool
    , version :: Text
    , service :: Text
    }
    deriving (Eq, Show, Generic)

instance ToJSON Health
instance FromJSON Health
instance ToSchema Health


-- ═══════════════════════════════════════════════════════════════════════════
-- // api info //
-- ═══════════════════════════════════════════════════════════════════════════

data ApiInfo = ApiInfo
    { name :: Text
    , version :: Text
    , description :: Text
    , docsUrl :: Text
    }
    deriving (Eq, Show, Generic)

instance ToJSON ApiInfo
instance FromJSON ApiInfo
instance ToSchema ApiInfo


-- ═══════════════════════════════════════════════════════════════════════════
-- // pagination //
-- ═══════════════════════════════════════════════════════════════════════════

data Pagination = Pagination
    { limit :: Int
    , offset :: Int
    , total :: Int
    }
    deriving (Eq, Show, Generic)

instance ToJSON Pagination
instance FromJSON Pagination
instance ToSchema Pagination

data PaginatedResponse a = PaginatedResponse
    { items :: [a]
    , pagination :: Pagination
    }
    deriving (Eq, Show, Generic)

instance ToJSON a => ToJSON (PaginatedResponse a)
instance FromJSON a => FromJSON (PaginatedResponse a)
instance ToSchema a => ToSchema (PaginatedResponse a)


-- ═══════════════════════════════════════════════════════════════════════════
-- // error response //
-- ═══════════════════════════════════════════════════════════════════════════

data ErrorResponse = ErrorResponse
    { error :: Text
    , code :: Text
    , details :: Maybe (Map Text Text)
    }
    deriving (Eq, Show, Generic)

instance ToJSON ErrorResponse
instance FromJSON ErrorResponse
instance ToSchema ErrorResponse

data SuccessResponse = SuccessResponse
    { success :: Bool
    , message :: Maybe Text
    }
    deriving (Eq, Show, Generic)

instance ToJSON SuccessResponse
instance FromJSON SuccessResponse
instance ToSchema SuccessResponse


-- ═══════════════════════════════════════════════════════════════════════════
-- // authentication //
-- ═══════════════════════════════════════════════════════════════════════════

newtype ApiKey = ApiKey { unApiKey :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData)

instance ToSchema ApiKey
instance ToParamSchema ApiKey

newtype AuthToken = AuthToken { unAuthToken :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData)

instance ToSchema AuthToken
instance ToParamSchema AuthToken

-- | Standard authorization header
type AuthHeader = Header "Authorization" Text


-- ═══════════════════════════════════════════════════════════════════════════
-- // timestamps //
-- ═══════════════════════════════════════════════════════════════════════════

newtype Timestamp = Timestamp { unTimestamp :: UTCTime }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON)

instance ToSchema Timestamp

data TimeRange = TimeRange
    { start :: Timestamp
    , end :: Timestamp
    }
    deriving (Eq, Show, Generic)

instance ToJSON TimeRange
instance FromJSON TimeRange
instance ToSchema TimeRange


-- ═══════════════════════════════════════════════════════════════════════════
-- // ids //
-- ═══════════════════════════════════════════════════════════════════════════

newtype ResourceId = ResourceId { unResourceId :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData)

instance ToSchema ResourceId
instance ToParamSchema ResourceId

newtype UserId = UserId { unUserId :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData)

instance ToSchema UserId
instance ToParamSchema UserId

newtype OrganizationId = OrganizationId { unOrganizationId :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData)

instance ToSchema OrganizationId
instance ToParamSchema OrganizationId


-- ═══════════════════════════════════════════════════════════════════════════
-- // common api patterns //
-- ═══════════════════════════════════════════════════════════════════════════

type HealthAPI = "health" :> Get '[JSON] Health

type InfoAPI = "info" :> Get '[JSON] ApiInfo
