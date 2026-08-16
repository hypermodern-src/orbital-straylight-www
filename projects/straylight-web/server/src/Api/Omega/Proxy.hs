-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                          // straylight-api // omega // proxy
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--
-- omega//proxy API
-- Verified inference proxy. SSE to SIGIL over ZeroMQ.
--
-- Features:
--   * SSE to SIGIL frame conversion
--   * Reset-on-ambiguity for hallucination prevention
--   * 200-600% wire compression
--   * Automatic tool call repair
--   * Multi-provider support
--
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module Api.Omega.Proxy
    ( -- * API
      ProxyAPI
    
      -- * Types
    , Endpoint (..)
    , InferenceProvider (..)
    , ProxyStats (..)
    , SigilConfig (..)
    , HotTable (..)
    , StreamSession (..)
    ) where

import Data.Aeson
import Data.OpenApi (ToSchema (..), ToParamSchema (..))
import Data.Text (Text)
import GHC.Generics
import Servant

import Api.Types


-- ═══════════════════════════════════════════════════════════════════════════
-- // types //
-- ═══════════════════════════════════════════════════════════════════════════

newtype EndpointId = EndpointId { unEndpointId :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData, ToParamSchema)

instance ToSchema EndpointId

newtype StreamId = StreamId { unStreamId :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData, ToParamSchema)

instance ToSchema StreamId

-- | Inference provider
data InferenceProvider = InferenceProvider
    { providerId :: Text
    , name :: Text
    , baseUrl :: Text
    , models :: [Text]
    , supportsStreaming :: Bool
    , supportsTools :: Bool
    }
    deriving (Eq, Show, Generic)

instance ToJSON InferenceProvider
instance FromJSON InferenceProvider
instance ToSchema InferenceProvider

-- | Proxy endpoint configuration
data Endpoint = Endpoint
    { endpointId :: EndpointId
    , name :: Text
    , provider :: Text
    , model :: Text
    , apiKeyRef :: Text           -- ^ Reference to secret
    , sigilEnabled :: Bool
    , compressionLevel :: Int
    , resetOnAmbiguity :: Bool
    , maxTokens :: Maybe Int
    }
    deriving (Eq, Show, Generic)

instance ToJSON Endpoint
instance FromJSON Endpoint
instance ToSchema Endpoint

-- | SIGIL protocol configuration
data SigilConfig = SigilConfig
    { hotTableSize :: Int
    , boundaryTokens :: [Int]
    , compressionEnabled :: Bool
    , frameBufferSize :: Int
    }
    deriving (Eq, Show, Generic)

instance ToJSON SigilConfig
instance FromJSON SigilConfig
instance ToSchema SigilConfig

-- | Hot token table
data HotTable = HotTable
    { tableId :: Text
    , model :: Text
    , vocabSize :: Int
    , hotTokens :: [Int]          -- ^ Top 127 token IDs
    , hash :: Text                -- ^ BLAKE3 hash
    , createdAt :: Timestamp
    }
    deriving (Eq, Show, Generic)

instance ToJSON HotTable
instance FromJSON HotTable
instance ToSchema HotTable

-- | Active stream session
data StreamSession = StreamSession
    { streamId :: StreamId
    , endpointId :: EndpointId
    , status :: Text              -- ^ "active" | "completed" | "error"
    , tokensProcessed :: Int
    , bytesIn :: Int              -- ^ SSE bytes received
    , bytesOut :: Int             -- ^ SIGIL bytes emitted
    , compressionRatio :: Double
    , toolCallsRepaired :: Int
    , resetCount :: Int           -- ^ Ambiguity resets
    , startedAt :: Timestamp
    , completedAt :: Maybe Timestamp
    }
    deriving (Eq, Show, Generic)

instance ToJSON StreamSession
instance FromJSON StreamSession
instance ToSchema StreamSession

-- | Proxy statistics
data ProxyStats = ProxyStats
    { totalRequests :: Integer
    , activeStreams :: Int
    , totalTokens :: Integer
    , totalBytesIn :: Integer
    , totalBytesOut :: Integer
    , averageCompression :: Double
    , toolCallsRepaired :: Integer
    , ambiguityResets :: Integer
    , requestsPerSecond :: Double
    , uptime :: Double            -- ^ Seconds
    }
    deriving (Eq, Show, Generic)

instance ToJSON ProxyStats
instance FromJSON ProxyStats
instance ToSchema ProxyStats

-- | Chat completion request (OpenAI-compatible)
data ChatRequest = ChatRequest
    { model :: Text
    , messages :: [Value]
    , maxTokens :: Maybe Int
    , temperature :: Maybe Double
    , tools :: Maybe [Value]
    , stream :: Maybe Bool
    }
    deriving (Eq, Show, Generic)

instance ToJSON ChatRequest
instance FromJSON ChatRequest
instance ToSchema ChatRequest


-- ═══════════════════════════════════════════════════════════════════════════
-- // api //
-- ═══════════════════════════════════════════════════════════════════════════

type ProxyAPI =
    "omega" :> "proxy" :> "v1" :>
        ( -- Health & Info
          HealthAPI
          :<|> InfoAPI
          
          -- OpenAI-compatible chat endpoint
          :<|> "chat" :> "completions" :> AuthHeader :> ReqBody '[JSON] ChatRequest :> Post '[JSON] Value
          :<|> "chat" :> "completions" :> AuthHeader :> ReqBody '[JSON] ChatRequest :> StreamPost NewlineFraming JSON (SourceIO Value)
          
          -- Providers
          :<|> "provider" :> AuthHeader :> Get '[JSON] [InferenceProvider]
          :<|> "provider" :> AuthHeader :> Capture "providerId" Text :> Get '[JSON] InferenceProvider
          
          -- Endpoints
          :<|> "endpoint" :> AuthHeader :> Get '[JSON] [Endpoint]
          :<|> "endpoint" :> AuthHeader :> ReqBody '[JSON] Endpoint :> Post '[JSON] Endpoint
          :<|> "endpoint" :> AuthHeader :> Capture "endpointId" EndpointId :> Get '[JSON] Endpoint
          :<|> "endpoint" :> AuthHeader :> Capture "endpointId" EndpointId :> ReqBody '[JSON] Endpoint :> Put '[JSON] Endpoint
          :<|> "endpoint" :> AuthHeader :> Capture "endpointId" EndpointId :> Delete '[JSON] SuccessResponse
          
          -- SIGIL configuration
          :<|> "sigil" :> "config" :> AuthHeader :> Get '[JSON] SigilConfig
          :<|> "sigil" :> "config" :> AuthHeader :> ReqBody '[JSON] SigilConfig :> Put '[JSON] SigilConfig
          :<|> "sigil" :> "hot-table" :> AuthHeader :> QueryParam "model" Text :> Get '[JSON] [HotTable]
          :<|> "sigil" :> "hot-table" :> AuthHeader :> Capture "tableId" Text :> Get '[JSON] HotTable
          :<|> "sigil" :> "hot-table" :> AuthHeader :> ReqBody '[JSON] HotTable :> Post '[JSON] HotTable
          
          -- Streams
          :<|> "stream" :> AuthHeader :> QueryParam "status" Text :> Get '[JSON] [StreamSession]
          :<|> "stream" :> AuthHeader :> Capture "streamId" StreamId :> Get '[JSON] StreamSession
          
          -- ZeroMQ endpoint info
          :<|> "zmq" :> AuthHeader :> Get '[JSON] Value
          
          -- Stats
          :<|> "stats" :> AuthHeader :> Get '[JSON] ProxyStats
        )

-- Note: SourceIO comes from Servant.API.Stream for streaming responses
