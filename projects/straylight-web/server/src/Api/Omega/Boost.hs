-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                          // straylight-api // omega // boost
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--
-- omega//boost API
-- Managed inference co-located with BYOK vendor. Custom CUTLASS kernels.
--
-- Features:
--   * CUTLASS 3.x sm_120 custom CUDA kernels
--   * Co-located with BYOK providers
--   * evring HTTP/1.1+2+3 stack
--   * Intelligent batching
--   * Auto-scaling without GPU ops
--
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module Api.Omega.Boost
    ( -- * API
      BoostAPI
    
      -- * Types
    , Deployment (..)
    , Model (..)
    , InferenceRequest (..)
    , InferenceStats (..)
    , KernelInfo (..)
    , Region (..)
    , UsageReport (..)
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

newtype DeploymentId = DeploymentId { unDeploymentId :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData, ToParamSchema)

instance ToSchema DeploymentId

newtype ModelId = ModelId { unModelId :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData, ToParamSchema)

instance ToSchema ModelId

-- | Supported regions (co-located with providers)
data Region = Region
    { regionId :: Text
    , name :: Text
    , provider :: Text            -- ^ "gcp" | "aws" | "azure"
    , colocatedWith :: [Text]     -- ^ ["openai", "anthropic"]
    , gpuType :: Text             -- ^ "h100" | "b200"
    , available :: Bool
    }
    deriving (Eq, Show, Generic)

instance ToJSON Region
instance FromJSON Region
instance ToSchema Region

-- | Custom CUDA kernel info
data KernelInfo = KernelInfo
    { kernelId :: Text
    , name :: Text
    , cutlassVersion :: Text      -- ^ "3.x"
    , smArch :: Text              -- ^ "sm_120"
    , optimizedFor :: Text        -- ^ "inference" | "batched_inference"
    , throughput :: Double        -- ^ Tokens/sec
    }
    deriving (Eq, Show, Generic)

instance ToJSON KernelInfo
instance FromJSON KernelInfo
instance ToSchema KernelInfo

-- | Model configuration
data Model = Model
    { modelId :: ModelId
    , name :: Text
    , provider :: Text            -- ^ Original provider ("openai", "anthropic")
    , contextLength :: Int
    , inputPrice :: Double        -- ^ $/1M tokens
    , outputPrice :: Double       -- ^ $/1M tokens
    , kernel :: KernelInfo
    , available :: Bool
    }
    deriving (Eq, Show, Generic)

instance ToJSON Model
instance FromJSON Model
instance ToSchema Model

-- | Deployment configuration
data Deployment = Deployment
    { deploymentId :: DeploymentId
    , name :: Text
    , model :: ModelId
    , region :: Text
    , apiKeyRef :: Text           -- ^ BYOK API key reference
    , minInstances :: Int
    , maxInstances :: Int
    , currentInstances :: Int
    , status :: Text              -- ^ "active" | "scaling" | "stopped"
    , createdAt :: Timestamp
    }
    deriving (Eq, Show, Generic)

instance ToJSON Deployment
instance FromJSON Deployment
instance ToSchema Deployment

-- | Inference statistics
data InferenceStats = InferenceStats
    { deploymentId :: DeploymentId
    , period :: Text              -- ^ "minute" | "hour" | "day"
    , requestCount :: Integer
    , tokenCount :: Integer
    , avgLatency :: Double        -- ^ ms
    , p50Latency :: Double
    , p99Latency :: Double
    , ttft :: Double              -- ^ Time to first token (ms)
    , throughput :: Double        -- ^ Tokens/sec
    , errorRate :: Double
    }
    deriving (Eq, Show, Generic)

instance ToJSON InferenceStats
instance FromJSON InferenceStats
instance ToSchema InferenceStats

-- | Usage report
data UsageReport = UsageReport
    { deploymentId :: Maybe DeploymentId
    , startDate :: Timestamp
    , endDate :: Timestamp
    , inputTokens :: Integer
    , outputTokens :: Integer
    , requests :: Integer
    , cost :: Double
    , savings :: Double           -- ^ Compared to direct provider
    }
    deriving (Eq, Show, Generic)

instance ToJSON UsageReport
instance FromJSON UsageReport
instance ToSchema UsageReport

-- | Inference request (OpenAI-compatible)
data InferenceRequest = InferenceRequest
    { model :: Text
    , messages :: [Value]
    , maxTokens :: Maybe Int
    , temperature :: Maybe Double
    , stream :: Maybe Bool
    }
    deriving (Eq, Show, Generic)

instance ToJSON InferenceRequest
instance FromJSON InferenceRequest
instance ToSchema InferenceRequest

-- | Create deployment request
data CreateDeploymentRequest = CreateDeploymentRequest
    { name :: Text
    , model :: ModelId
    , region :: Text
    , apiKeyRef :: Text
    , minInstances :: Maybe Int
    , maxInstances :: Maybe Int
    }
    deriving (Eq, Show, Generic)

instance ToJSON CreateDeploymentRequest
instance FromJSON CreateDeploymentRequest
instance ToSchema CreateDeploymentRequest


-- ═══════════════════════════════════════════════════════════════════════════
-- // api //
-- ═══════════════════════════════════════════════════════════════════════════

type BoostAPI =
    "omega" :> "boost" :> "v1" :>
        ( -- Health & Info
          HealthAPI
          :<|> InfoAPI
          
          -- OpenAI-compatible inference
          :<|> "chat" :> "completions" :> AuthHeader :> ReqBody '[JSON] InferenceRequest :> Post '[JSON] Value
          :<|> "chat" :> "completions" :> AuthHeader :> ReqBody '[JSON] InferenceRequest :> StreamPost NewlineFraming JSON (SourceIO Value)
          
          -- Models
          :<|> "model" :> AuthHeader :> Get '[JSON] [Model]
          :<|> "model" :> AuthHeader :> Capture "modelId" ModelId :> Get '[JSON] Model
          
          -- Regions
          :<|> "region" :> AuthHeader :> Get '[JSON] [Region]
          :<|> "region" :> AuthHeader :> Capture "regionId" Text :> Get '[JSON] Region
          
          -- Deployments
          :<|> "deployment" :> AuthHeader :> Get '[JSON] [Deployment]
          :<|> "deployment" :> AuthHeader :> ReqBody '[JSON] CreateDeploymentRequest :> Post '[JSON] Deployment
          :<|> "deployment" :> AuthHeader :> Capture "deploymentId" DeploymentId :> Get '[JSON] Deployment
          :<|> "deployment" :> AuthHeader :> Capture "deploymentId" DeploymentId :> ReqBody '[JSON] Deployment :> Put '[JSON] Deployment
          :<|> "deployment" :> AuthHeader :> Capture "deploymentId" DeploymentId :> Delete '[JSON] SuccessResponse
          :<|> "deployment" :> AuthHeader :> Capture "deploymentId" DeploymentId :> "scale" :> ReqBody '[JSON] Value :> Post '[JSON] Deployment
          :<|> "deployment" :> AuthHeader :> Capture "deploymentId" DeploymentId :> "start" :> Post '[JSON] Deployment
          :<|> "deployment" :> AuthHeader :> Capture "deploymentId" DeploymentId :> "stop" :> Post '[JSON] Deployment
          
          -- Stats & Metrics
          :<|> "deployment" :> AuthHeader :> Capture "deploymentId" DeploymentId :> "stats" :> QueryParam "period" Text :> Get '[JSON] InferenceStats
          :<|> "deployment" :> AuthHeader :> Capture "deploymentId" DeploymentId :> "logs" :> QueryParam "limit" Int :> Get '[JSON] [Value]
          
          -- Usage & Billing
          :<|> "usage" :> AuthHeader :> QueryParam "deploymentId" DeploymentId :> QueryParam "start" Text :> QueryParam "end" Text :> Get '[JSON] UsageReport
          
          -- Kernels
          :<|> "kernel" :> AuthHeader :> Get '[JSON] [KernelInfo]
          :<|> "kernel" :> AuthHeader :> Capture "kernelId" Text :> Get '[JSON] KernelInfo
        )

-- Note: SourceIO comes from Servant.API.Stream for streaming responses
