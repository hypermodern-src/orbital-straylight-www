-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--                                    // straylight-api // sensenet // converge
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--
-- sensenet//converge API
-- Typed infrastructure-as-code. Desired-state convergence.
--
-- Features:
--   * Dhall-typed infrastructure definitions
--   * Desired-state convergence (no state files)
--   * Live drift detection
--   * Multi-cloud support (AWS, GCP, Azure, K8s)
--   * Idempotent operations with formal guarantees
--
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module Api.Sensenet.Converge
    ( -- * API
      ConvergeAPI
    
      -- * Types
    , Topology (..)
    , Resource (..)
    , ResourceState (..)
    , ResourceDiff (..)
    , ConvergeJob (..)
    , ConvergeStatus (..)
    , DriftReport (..)
    , Provider (..)
    ) where

import Data.Aeson
import Data.OpenApi (ToSchema (..), ToParamSchema (..))
import Data.Text (Text)
import GHC.Generics
import Servant
import Web.HttpApiData (FromHttpApiData (..), ToHttpApiData (..))

import Api.Types


-- ═══════════════════════════════════════════════════════════════════════════
-- // types //
-- ═══════════════════════════════════════════════════════════════════════════

newtype TopologyId = TopologyId { unTopologyId :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData, ToParamSchema)

instance ToSchema TopologyId

newtype ResourceId' = ResourceId' { unResourceId' :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData, ToParamSchema)

instance ToSchema ResourceId'

newtype JobId = JobId { unJobId :: Text }
    deriving (Eq, Show, Generic)
    deriving newtype (ToJSON, FromJSON, FromHttpApiData, ToHttpApiData, ToParamSchema)

instance ToSchema JobId

-- | Converge operation status
data ConvergeStatus
    = Converging
    | Converged
    | Drifted
    | ConvergeFailed
    deriving (Eq, Show, Generic)

instance ToJSON ConvergeStatus where
    toJSON Converging = "converging"
    toJSON Converged = "converged"
    toJSON Drifted = "drifted"
    toJSON ConvergeFailed = "failed"

instance FromJSON ConvergeStatus where
    parseJSON = withText "ConvergeStatus" $ \case
        "converging" -> pure Converging
        "converged" -> pure Converged
        "drifted" -> pure Drifted
        "failed" -> pure ConvergeFailed
        _ -> fail "Invalid converge status"

instance ToSchema ConvergeStatus

instance ToHttpApiData ConvergeStatus where
    toUrlPiece Converging = "converging"
    toUrlPiece Converged = "converged"
    toUrlPiece Drifted = "drifted"
    toUrlPiece ConvergeFailed = "failed"

instance FromHttpApiData ConvergeStatus where
    parseUrlPiece "converging" = Right Converging
    parseUrlPiece "converged" = Right Converged
    parseUrlPiece "drifted" = Right Drifted
    parseUrlPiece "failed" = Right ConvergeFailed
    parseUrlPiece _ = Left "Invalid converge status"

instance ToParamSchema ConvergeStatus

-- | Resource state
data ResourceState
    = Desired
    | Actual
    | Unknown
    deriving (Eq, Show, Generic)

instance ToJSON ResourceState
instance FromJSON ResourceState
instance ToSchema ResourceState

-- | Cloud provider
data Provider = Provider
    { providerId :: Text
    , providerType :: Text        -- ^ "gcp" | "aws" | "azure" | "k8s"
    , region :: Maybe Text
    , project :: Maybe Text
    , credentials :: Maybe Text   -- ^ Reference to secret, not actual creds
    }
    deriving (Eq, Show, Generic)

instance ToJSON Provider
instance FromJSON Provider
instance ToSchema Provider

-- | Infrastructure resource
data Resource = Resource
    { resourceId :: ResourceId'
    , resourceType :: Text        -- ^ "compute_instance" | "storage_bucket" | etc
    , name :: Text
    , provider :: Text
    , desiredState :: Value       -- ^ Dhall-derived JSON
    , actualState :: Maybe Value  -- ^ Queried from provider
    , status :: ConvergeStatus
    , dependencies :: [ResourceId']
    }
    deriving (Eq, Show, Generic)

instance ToJSON Resource
instance FromJSON Resource
instance ToSchema Resource

-- | Diff between desired and actual state
data ResourceDiff = ResourceDiff
    { resourceId :: ResourceId'
    , diffType :: Text            -- ^ "create" | "update" | "delete" | "no_change"
    , changes :: [Value]          -- ^ List of field changes
    , requiresRecreate :: Bool
    }
    deriving (Eq, Show, Generic)

instance ToJSON ResourceDiff
instance FromJSON ResourceDiff
instance ToSchema ResourceDiff

-- | Infrastructure topology
data Topology = Topology
    { topologyId :: TopologyId
    , name :: Text
    , domain :: Maybe Text
    , providers :: [Provider]
    , resources :: [Resource]
    , dhallSource :: Text
    , dhallHash :: Text
    , version :: Int
    }
    deriving (Eq, Show, Generic)

instance ToJSON Topology
instance FromJSON Topology
instance ToSchema Topology

-- | Drift detection report
data DriftReport = DriftReport
    { topologyId :: TopologyId
    , detectedAt :: Timestamp
    , driftedResources :: [ResourceDiff]
    , totalResources :: Int
    , driftPercentage :: Double
    }
    deriving (Eq, Show, Generic)

instance ToJSON DriftReport
instance FromJSON DriftReport
instance ToSchema DriftReport

-- | Converge job
data ConvergeJob = ConvergeJob
    { jobId :: JobId
    , topologyId :: TopologyId
    , operation :: Text           -- ^ "up" | "down" | "refresh" | "plan"
    , status :: ConvergeStatus
    , startedAt :: Maybe Timestamp
    , completedAt :: Maybe Timestamp
    , plan :: [ResourceDiff]
    , appliedChanges :: Int
    , errors :: [Text]
    }
    deriving (Eq, Show, Generic)

instance ToJSON ConvergeJob
instance FromJSON ConvergeJob
instance ToSchema ConvergeJob

-- | Converge request
data ConvergeRequest = ConvergeRequest
    { operation :: Text
    , dryRun :: Bool
    , autoApprove :: Bool
    , targetResources :: Maybe [ResourceId']
    }
    deriving (Eq, Show, Generic)

instance ToJSON ConvergeRequest
instance FromJSON ConvergeRequest
instance ToSchema ConvergeRequest


-- ═══════════════════════════════════════════════════════════════════════════
-- // api //
-- ═══════════════════════════════════════════════════════════════════════════

type ConvergeAPI =
    "sensenet" :> "converge" :> "v1" :>
        ( -- Health & Info
          HealthAPI
          :<|> InfoAPI
          
          -- Topologies
          :<|> "topology" :> AuthHeader :> Get '[JSON] [Topology]
          :<|> "topology" :> AuthHeader :> Capture "topologyId" TopologyId :> Get '[JSON] Topology
          :<|> "topology" :> AuthHeader :> ReqBody '[JSON] Topology :> Post '[JSON] Topology
          :<|> "topology" :> AuthHeader :> Capture "topologyId" TopologyId :> ReqBody '[JSON] Topology :> Put '[JSON] Topology
          :<|> "topology" :> AuthHeader :> Capture "topologyId" TopologyId :> Delete '[JSON] SuccessResponse
          
          -- Resources
          :<|> "topology" :> AuthHeader :> Capture "topologyId" TopologyId :> "resource" :> Get '[JSON] [Resource]
          :<|> "topology" :> AuthHeader :> Capture "topologyId" TopologyId :> "resource" :> Capture "resourceId" ResourceId' :> Get '[JSON] Resource
          
          -- Converge operations
          :<|> "topology" :> AuthHeader :> Capture "topologyId" TopologyId :> "converge" :> ReqBody '[JSON] ConvergeRequest :> Post '[JSON] ConvergeJob
          :<|> "topology" :> AuthHeader :> Capture "topologyId" TopologyId :> "plan" :> Post '[JSON] [ResourceDiff]
          :<|> "topology" :> AuthHeader :> Capture "topologyId" TopologyId :> "refresh" :> Post '[JSON] Topology
          
          -- Drift detection
          :<|> "topology" :> AuthHeader :> Capture "topologyId" TopologyId :> "drift" :> Get '[JSON] DriftReport
          :<|> "topology" :> AuthHeader :> Capture "topologyId" TopologyId :> "watch" :> Post '[JSON] SuccessResponse
          
          -- Jobs
          :<|> "job" :> AuthHeader :> QueryParam "topologyId" TopologyId :> QueryParam "status" ConvergeStatus :> Get '[JSON] [ConvergeJob]
          :<|> "job" :> AuthHeader :> Capture "jobId" JobId :> Get '[JSON] ConvergeJob
          :<|> "job" :> AuthHeader :> Capture "jobId" JobId :> "cancel" :> Post '[JSON] ConvergeJob
          :<|> "job" :> AuthHeader :> Capture "jobId" JobId :> "logs" :> Get '[PlainText] Text
          
          -- Providers
          :<|> "provider" :> AuthHeader :> Get '[JSON] [Provider]
          :<|> "provider" :> AuthHeader :> Capture "providerId" Text :> Get '[JSON] Provider
        )
